require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')

class TestClassOne < ActiveFedora::Base
  include HullModelMethods


  def owner_id
    "fooAdmin"
  end
end


describe HullModelMethods do
  before(:each) do
    @testclassone = TestClassOne.new
#mock_desc_ds.stubs(:remove_subject_topic)
    
#    mock_content_ds = mock("Datastream")
#    mock_content_ds.stubs(:insert_resource).returns(mock_node,0)
#    @testclassone.stubs(:datastreams_in_memory).returns({"descMetadata"=>mock_desc_ds, "contentMetadata"=>mock_content_ds})
  end

  it "should provide insert/remove methods for subject_topic" do
    @testclassone.respond_to?(:insert_subject_topic).should be_true
    @testclassone.respond_to?(:remove_subject_topic).should be_true
  end

  describe "#insert_subject_topic" do
    it "should wrap the insert_subject_topic of the underlying datastream" do
      mock_desc_ds = mock("Datastream")
      mock_node = mock("subject_node")
      mock_node.expects(:inner_text=).with("foobar")
      mock_desc_ds.expects(:insert_subject_topic).returns(mock_node,0)
      @testclassone.stubs(:datastreams_in_memory).returns({"descMetadata"=>mock_desc_ds})
      node, index = @testclassone.insert_subject_topic(:value => "foobar") 
    end
  end

  it "should provide a helper method for inserting resource records into contentMetatdat" do
    @testclassone.respond_to?(:insert_resource)
  end

  describe "cmodel" do
    it "should properly return the appropriate c-Model declaration" do
      helper.stubs(:class).returns(JournalArticle)
      helper.cmodel.should == "info:fedora/hull-cModel:journalArticle"
      
      @testclassone.cmodel.should == "info:fedora/hull-cModel:testClassOne"
    end
  end
  describe "to_solr" do
    it "should apply has_model_s and fedora_owner_id correctly" do
      solr_doc = @testclassone.to_solr
      solr_doc["has_model_s"].should == "info:fedora/hull-cModel:testClassOne"
      solr_doc["fedora_owner_id_s"].should == "fooAdmin"
      solr_doc["fedora_owner_id_display"].should == "fooAdmin"
    end
  end

end