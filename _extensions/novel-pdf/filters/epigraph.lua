local utils = require "../utils"

if not FORMAT:match 'latex' then
	return
end

-- LaTeX multiline strings declared here so that it does not have useless indentation
local raw_latex_open_format <const> = [[
\vspace*{%(lines_before)s\nbs}
\begin{adjustwidth}{%(lmargin)s}{%(rmargin)s}
{\itshape]]

local raw_latex_close_format <const> = [[
\par}
\hfill--- %(by)s, ``%(from)s''\par
\end{adjustwidth}
\vspace*{%(lines_after)s\nbs}]]

-- global variables needed to communicate between different filters
local g = {
	from_meta = {},
}


-- Used localy inside epigraph div
local make_para_noindent = {
	Para = function(para)
		return { {pandoc.RawInline('latex', [[\noindent ]])} .. para.content}
	end
}

function epigraph_from_div(div)
	if utils.table_contains(div.classes, "epigraph") then
		-- Retreive the relevant attributes of the div if provided
		-- Eventualy defaulting to value provided in meta
		local lmargin = pandoc.utils.stringify(div.attributes.lmargin or g.from_meta.epigraphs.lmargin)
		local rmargin = pandoc.utils.stringify(div.attributes.rmargin or g.from_meta.epigraphs.rmargin)
		local lines_before = pandoc.utils.stringify(div.attributes.lines_before or g.from_meta.epigraphs.lines_before)
		assert(tonumber(lines_before),
			"invalid lines_before attribute or meta: %(actual) is not a number" % {actual=lines_before})
		local lines_after = pandoc.utils.stringify(div.attributes.lines_after or g.from_meta.epigraphs.lines_after)
		assert(tonumber(lines_after),
			"invalid lines_after attribute or meta: %(actual) is not a number" % {actual=lines_after})
		local keepindent = (div.attributes.keepindent ~= nil or g.from_meta.epigraphs.keepindent)
		assert(pandoc.utils.type(keepindent) == 'boolean',
			"invalid keepindent attribute or meta: $(actual)s is not a boolean" % {actual=keepindent})

		-- local attributes (with no meta default value)
		local by = div.attributes.by and pandoc.utils.stringify(div.attributes.by)
		local from = div.attributes.from and pandoc.utils.stringify(div.attributes.from)

		-- Now we generate the LaTeX code for the div
		local raw_latex_open = raw_latex_open_format % {lines_before=lines_before, lmargin=lmargin, rmargin=rmargin}

		local content
		if keepindent then
	    	content = div:walk()
	    else
	    	content = div:walk(make_para_noindent)
	    end

		local raw_latex_close = raw_latex_close_format % {by=by, from=from, lines_after=lines_after}

		return {
			pandoc.RawBlock('tex', raw_latex_open),
			content,
			pandoc.RawBlock('tex', raw_latex_close),
		}
	end

	-- if the div doesn't have the correct class we are not touching it
	return nil
end

-- Set what function will be called on what kind of Pandoc element and in which order
-- See: https://pandoc.org/lua-filters.html#typewise-traversal
return {
	{
		Meta = function(meta) g.from_meta = meta end
	},
	{
		Div = epigraph_from_div
	}
}
