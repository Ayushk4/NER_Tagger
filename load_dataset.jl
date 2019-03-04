PARAMETERS = Dict{String, Any}()
PARAMETERS["TRAIN_PATH"] = "train.txt"
PARAMETERS["DEV_PATH"] = "dev.txt"
PARAMETERS["TEST_PATH"] = "test.txt"
PARAMETERS["TO_LOWERCASE"] = true
PARAMETERS["ZERO_ALL_NUMS"] = true
PARAMETERS["TAGGING_SCHEME"] = "BIOES" # In the paper, this tagging scheme was found to give the highest accuracy

function zero_digits(str::AbstractString)
    replace(str, r"\d" => "0")
end

"""
Load sentences. A line must contain at least a word and its tag.
Sentences are separated by empty lines.
"""
function load_sentences(path, zeros)
  sentences = []
  sentence = []
  for line in readlines(path)
    if zeros 
      line = zero_digits(rstrip(line))
    else
      line = strip(line)
    end

    if isempty(line) && length(sentence) > 0
        if !occursin("DOCSTART", sentence[1][1])
          push!(sentences, sentence)
        end
        sentence = []
    else
      word = split(line)
      @assert length(word) >= 2
      push!(sentence, word)
    end      
  end

  if length(sentence) > 0
    if !occursin("DOCSTART", sentence[1][1])
      push!(sentences, sentence)
    end
  end
  sentences
end

train_sentences = load_sentences(PARAMETERS["TRAIN_PATH"], PARAMETERS["ZERO_ALL_NUMS"])
dev_sentences = load_sentences(PARAMETERS["DEV_PATH"], PARAMETERS["ZERO_ALL_NUMS"])
test_sentences = load_sentences(PARAMETERS["TEST_PATH"], PARAMETERS["ZERO_ALL_NUMS"])

"""
Check that tags have a valid BIO format.
Tags in BIO1 format are converted to BIO2.
"""
# k = ["I-ORG", "O", "I-MISC", "O", "O", "O", "B-MISC", "I-MISC", "I-LOC", "O", "O"]
function check_valid_BIO(tags)

    for (i,tag) in enumerate(tags)
        if (typeof(tag)) == Char
            println(tags)
            println(i)
            println("\n\n\n")
        end
        if tag != "O"
            current_tag = split(tag,'-')
            bio_part = (current_tag[1])[1]
            if length(current_tag) != 2 || ∉(bio_part, ['I', 'B'])
                return false
            end
            
            if bio_part == 'B'
                continue
            elseif i == 1 || tags[i - 1] == "O"  # conversion IOB1 to IOB2
                tags[i] = "B" * tag[2:end]
            elseif tags[i - 1][2:end] == tag[2:end]
                continue
            else  # conversion IOB1 to IOB2
                tags[i] = "B" * tag[2:end]
            end

        end
    end
    return true
end
print(@time check_valid_BIO(k))

"""
the function is used to convert
BIO -> BIOES tagging
"""
function BIO_to_BIOES(tags)
    new_tags = []
    for (i, tag) in enumerate(tags)

        if tag == "O"
            push!(new_tags, tag)
        elseif split(tag, '-')[1] == "B"
            if i+1 <= length(tags) && split(tags[i+1], '-')[1] == "I"
                push!(new_tags, tag)
            else
                push!(new_tags, replace(tag, "B-" => "S-"))
            end

        elseif split(tag, '-')[1] == "I"
            if i+1 <= length(tags) && split(tags[i+1], '-')[1] == "I"
                push!(new_tags, tag)
            else
                push!(new_tags, replace(tag, "I-" => "E-"))
            end
            
        else
            throw("Invalid BIO format of tagging!")
        end
    end
    return new_tags
end
# k = ["B-ORG", "O", "B-MISC", "O", "O", "O", "B-MISC", "I-MISC", "I-LOC", "O", "O"]

# @time BIO_to_BIOES(k)

"""
Check BIO tagging scheme and update sentences tagging scheme to BIOES.
"""
function convert_to_BIOES(sentences::Array{Any,1})
    tag_scheme = PARAMETERS["TAGGING_SCHEME"]
    for i in eachindex(sentences)
        # Sent is Array with each element of the format "<Word> <POS> <syntactic chunk> <NER-Tag>"
        tags = [element[end] for element in sentences[i]]
#         println(i)
        if !check_valid_BIO(tags)
            sent = join([element[1] for element in sentences[i]], " ")
            throw("Sentences should be given in BIO format! Please check sentence : $sent")
        end
        if tag_scheme == "BIOES"
            new_tags = BIO_to_BIOES(tags)
            for j in eachindex(sentences[i])
                ((sentences[i])[j])[end] = new_tags[j]

            end
        else
            throw("Wrong tagging scheme!")
        end
    end
#     println(sentences)
end

convert_to_BIOES(train_sentences)
convert_to_BIOES(test_sentences)
convert_to_BIOES(dev_sentences)
