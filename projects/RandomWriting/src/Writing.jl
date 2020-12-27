module Writing

# using Turing

const WordList = Array{SubString{String}, 1}
const CountSubdict = Dict{SubString, Int}
const CountDict = Dict{WordList, CountSubdict}

const ProbaSubdict = Dict{SubString, Float64}
const ProbaDict = Dict{WordList, ProbaSubdict}


function read_text_file(path::String)::WordList
    open(path) do f
        text = read(f, String)
        wordlist = clean_text_for_kgrams(text)
        return wordlist
    end
end

function _do_punct_separation(word::SubString)::WordList
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


function get_grams(wordlist::WordList, gramsize::Int)::ProbaDict
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
    
    return _normalize_subdicts(distributions)
end


function _normalize_subdicts(distributions::CountDict)::ProbaDict
    """
    Turns sub-dictionaries of counts into sub-dictionaries of probabilities.
    """
    proper_distributions = ProbaDict()
    for prefix in keys(distributions)
        total = sum(values(distributions[prefix]))
        proba_subdict = ProbaSubdict()
        for next in keys(distributions[prefix])
            proba_subdict[next] = distributions[prefix][next] / total
        end
        proper_distributions[prefix] = proba_subdict
    end
    return proper_distributions
end


end
