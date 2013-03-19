xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
        
  xml.channel {
          
    xml.title("Hydra, University of Hull Digital Repository")
    xml.link(catalog_index_url(params))
    xml.description("Hydra - List of resources by search query")
    xml.language('en-gb')
    @document_list.each do |doc|
      xml.item do
        #Populate title var with doc title if poss, otherwise use id..
        title =  (doc[:title_t].present? and doc[:title_t].kind_of?(Array)) ? doc[:title_t].first : doc[:id]
        xml.title (title)                             
        xml.link(catalog_url(doc[:id]))                                   
                
        authors  = get_persons_from_roles(doc, ['creator','author'])
        names = authors.map {|person| person[:name]}  if authors.present?
        xml.author( names.join("; ") ) if names.present?   
      end
    end
          
  }
}
