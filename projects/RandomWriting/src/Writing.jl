module Writing

# using Turing
# using Base

const WordList = Array{SubString{String}, 1}
const CountSubdict = Dict{SubString, Int}
const CountDict = Dict{WordList, CountSubdict}

const EmpiricalDistribution = Dict{SubString, Float64}
const ProbaDict = Dict{WordList, EmpiricalDistribution}

const Author = String

GUTENBERG_BOOKS_PATH = "../data/Gutenberg/txt"

function read_text_file(path::String)::WordList
    open(path) do f
        text = read(f, String)
        wordlist = clean_text_for_kgrams(text)
        return wordlist
    end
end

function _do_punct_separation(word::SubString)::WordList
    """
    Splits word into [word, punctuation mark] 
    if word ends with a punctuation mark.
    """
    puncts = split(".;,()-{}[]&*^%\$#@!\\/", "")
    for punct in puncts
        if endswith(word, punct)
            clean_word = replace(word, punct => "")
            return [clean_word, punct]
        end
    end
    return [word]
end

function _separate_punct(split_text::WordList)::WordList
    """
    Adds split-off punctuation marks as words of their own, in
    order, in the input text.
    """
    wordlist = []
    for word in split_text
        result = _do_punct_separation(word)
        for word in result
            push!(wordlist, word)
        end
    end
    return wordlist
end


function clean_text_for_kgrams(text::String)::WordList    
    text = lowercase(text)
    split_text = split(text)
    split_text = _separate_punct(split_text)
    return split_text
end


function filter_gutenberg(author::String)::Array{String, 1}
    """
    Returns the paths to all files in the Gutenberg directory that
    have author in their filename.
    """
    files = readdir(GUTENBERG_BOOKS_PATH)
    filenames = filter(fname -> occursin(author, fname), files)
    return [joinpath(GUTENBERG_BOOKS_PATH, fname) for fname in filenames]
end


function get_grams(wordlist::WordList, gramsize::Int)::CountDict
    """
    Counts the number of times each word follows each prefix of gramsize words.
    """
    distributions = CountDict()
    for i in 1:(length(wordlist) - gramsize - 2)
        prefix = wordlist[i:(i + gramsize - 1)]
        next = wordlist[i + gramsize]
        if prefix ∉ keys(distributions)
            distributions[prefix] = CountSubdict()
        end
        if next ∉ keys(distributions[prefix])
            distributions[prefix][next] = 0
        end
        distributions[prefix][next] += 1
    end
    return distributions
end


function _normalize_subdicts(distributions::CountDict)::ProbaDict
    """
    Turns sub-dictionaries of counts into sub-dictionaries of probabilities.
    """
    proper_distributions = ProbaDict()
    for prefix in keys(distributions)
        total = sum(values(distributions[prefix]))
        proba_subdict = EmpiricalDistribution()
        for next in keys(distributions[prefix])
            proba_subdict[next] = distributions[prefix][next] / total
        end
        proper_distributions[prefix] = proba_subdict
    end
    return proper_distributions
end


function union_counts(counts::Array{CountDict, 1})::CountDict
    """
    Sums all the sub-entries from all the input CountDicts to make
    one big sum-of-all CountDict.
    """
    combined_distributions = CountDict()
    for count_dict in counts
        for prefix in keys(count_dict)
            if prefix ∉ keys(combined_distributions)
                combined_distributions[prefix] = Dict()
            end
            for next in keys(count_dict[prefix])
                combined_distributions[prefix][next] = (
                    1 + get(combined_distributions[prefix], next, 0))
            end
        end
    end
    return combined_distributions    
end

function generate_from(distributions::ProbaDict, len::Int)::nothing
    """
    Writes len words from the input distribution. Starts with
    a random prefix, then proceeds according to the distributions.
    """
    prefix = rand(keys(distributions))
    print(prefix)    
    for _ in 1:len
        print(" ")
        distribution = distributions[prefix]
        r = rand(1)[1]
        closest_dist = 100
        closest_word = nothing
        for (word, p) in distribution
            dist = abs(r - p)
            if dist < closest_dist
                closest_dist = dist
                closest_word = word
            end
        end
        prefix = prefix[2:end]
        push!(prefix, closest_word)
        print(closest_word)        
    end
end

generate_from(d::ProbaDict)::nothing = generate_from(d, 1000)


function get_distributions(author::Author)::ProbaDict
    """
    Gets the combined probability distribution 
    over all the files by the passed author.
    """
    files = filter_gutenberg(author)
    gram_counts = Array{CountDict, 1}()
    for file in files
        wordlist = read_text_file(file)
        onegrams = get_grams(wordlist, 1)
        push!(gram_counts, onegrams)
    end
    combined_counts::CountDict = union_counts(gram_counts)
    distributions = _normalize_subdicts(combined_counts)
    return distributions
end

end
