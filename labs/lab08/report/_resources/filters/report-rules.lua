-- Keep thematic rules inside the text area when Word files are opened in LibreOffice.
function HorizontalRule(element)
  if FORMAT == 'docx' then
    return pandoc.RawBlock('openxml', [[
<w:p><w:pPr><w:spacing w:before="80" w:after="80"/>
<w:ind w:left="0" w:right="0" w:firstLine="0"/>
<w:pBdr><w:bottom w:val="single" w:sz="4" w:space="1" w:color="B0B0B0"/></w:pBdr>
</w:pPr></w:p>]])
  end
  return element
end
