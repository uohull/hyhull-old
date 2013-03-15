xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
        
  xml.channel {
          
    xml.title("Hydra, University of Hull Digital Repository")
    xml.link(catalog_index_url(params))
    xml.description("Hydra - List of resources by search query")
    xml.language('en-gb')
    @document_list.each do |doc|
      xml.item do
        xml.title( doc[:title_t][0] || doc[:id] )                              
        xml.link(catalog_url(doc[:id]))                                   
        #xml.author( doc.to_semantic_values[:author][0] ) if doc.to_semantic_values[:author][0]  
        authors = get_persons_from_roles(doc, ['creator','author']).map {|person| person[:name]} 
        xml.author( authors.join("; ") ) if authors.present?   
      end
    end
          
  }
}
