makeLabel = (s, align=0) =>
  s = s.replace /[A-Z]/, (m) -> " "+m
  s = s[0].toUpperCase()+s[1..]

  if align
    count = align - s.length
    count = 0 if count < 0
    s + " ".repeat(count)
  else
    s

addressLink = (n,a)  =>
  """<a href="mailto:#{a}" title="#{a}">#{n}</a>"""

module.exports = {makeLabel, addressLink}
