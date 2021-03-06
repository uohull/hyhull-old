require 'spec_helper'
require 'user_helper'


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe AssetsController do
  
  before do
    request.env['WEBAUTH_USER']='bob'
  end
  
  it "should use DocumentController" do
    controller.should be_an_instance_of(AssetsController)
  end

  describe "#update_set_membership" do
    before do
      @ss = StructuralSet.find('hull:3374')
      @ss.defaultObjectRights.edit_access.machine.group= 'researcher'
      @ss.save
    end
    describe "with a non-structural set" do

      it "Should update the relationships for a non-Structural Set" do
        @document = ExamPaper.new
        controller = AssetsController.new
        controller.instance_variable_set :@document, @document
        controller.params = {'Structural Set' => "info:fedora/hull:3374" }
        
        controller.send :update_set_membership
        @document.relationships(:is_member_of).should == ["info:fedora/hull:protoQueue","info:fedora/hull:3374"]
        @document.relationships(:is_governed_by).should == ["info:fedora/hull:protoQueue"]
     		
			  #Change of logic, rights are not inherited from new StructuralSet when in Proto/QA queue, causes this test to fail
        #@document.rightsMetadata.edit_access.machine.group.should == ['researcher']
			
        controller.params = {'Structural Set' => "info:fedora/hull:3374", 'Display Set' => 'info:fedora/hull:9' }
        controller.send :update_set_membership
        @document.relationships(:is_member_of).should include("info:fedora/hull:protoQueue","info:fedora/hull:3374", "info:fedora/hull:9")
				#Object is not goverened_by the structural set until it is out of the queues...        
				@document.relationships(:is_governed_by).should == ["info:fedora/hull:protoQueue"]
							

        controller.params = {'Display Set' => ['info:fedora/hull:9'] }
        controller.send :update_set_membership
        @document.relationships(:is_member_of).should == ["info:fedora/hull:protoQueue","info:fedora/hull:9"]
        @document.relationships(:is_governed_by).should == ["info:fedora/hull:protoQueue"]

        ### Deleting
        controller.params = {'Display Set' => [''], 'Structural Set' => [""] }
        controller.send :update_set_membership
        @document.relationships(:is_member_of).should == ["info:fedora/hull:protoQueue"]
        @document.relationships(:is_governed_by).should == ["info:fedora/hull:protoQueue"]

      end	
    end
    it "Should update the relationships for a Structural Set" do
      @document = StructuralSet.new
      controller = AssetsController.new
      controller.instance_variable_set :@document, @document
      controller.params = {'Structural Set' => "info:fedora/hull:3374" }
      
      controller.send :update_set_membership
      @document.relationships(:is_member_of).should == ["info:fedora/hull:3374"]
      @document.relationships(:is_governed_by).should == ["info:fedora/hull-apo:structuralSet"]
      ## rightsMetadata should be a clone of hull-apo:structuralSet
      @document.rightsMetadata.edit_access.machine.group.should == ['contentAccessTeam']
      ## defaultObjectRights should be a clone of hull:3374(which was updated in the begin block)
      @document.defaultObjectRights.edit_access.machine.group.should == ['researcher']

      controller.params = {'Structural Set' => "info:fedora/hull:3374", 'Display Set' => 'info:fedora/hull:9' }
      controller.send :update_set_membership
      @document.relationships(:is_member_of).should include("info:fedora/hull:3374", "info:fedora/hull:9")
      @document.relationships(:is_governed_by).should == ["info:fedora/hull-apo:structuralSet"]
      @document.rightsMetadata.edit_access.machine.group.should == ['contentAccessTeam']

      controller.params = {'Display Set' => ['info:fedora/hull:9'] }
      controller.send :update_set_membership
      @document.relationships(:is_member_of).should == ["info:fedora/hull:9"]
      @document.relationships(:is_governed_by).should == ["info:fedora/hull-apo:structuralSet"]
      @document.rightsMetadata.edit_access.machine.group.should == ['contentAccessTeam']

      ### Deleting
      controller.params = {'Display Set' => [''] }
      controller.send :update_set_membership
      @document.relationships(:is_member_of).should be_empty
      @document.relationships(:is_governed_by).should == ["info:fedora/hull-apo:structuralSet"]
      @document.rightsMetadata.edit_access.machine.group.should == ['contentAccessTeam']

    end

    after do
      @ss.defaultObjectRights.edit_access.machine.group= 'contentAccessTeam'
      @ss.defaultObjectRights.save
    end


  end
  
  describe "update" do
    
    it "should load the appropriate filters" do
      expected_filters = [:load_document, :search_session, :history_session, :sanitize_update_params, :require_solr, :check_embargo_date_format, :enforce_access_controls, :update_set_membership, :validate_parameters]
      filters = AssetsController._process_action_callbacks.map(&:filter)
      expected_filters.each do |filter|
        filters.should include filter 
      end
    end
    
    it "should call custom hull filters" do
      mock_document = mock("document")
      mock_document.stubs(:update_from_computing_id).returns(nil)
      mock_document.stubs(:respond_to?).with(:apply_governed_by).returns(true)
      mock_document.stubs(:respond_to?).with(:apply_base_metadata).returns(true)
      mock_document.expects(:apply_base_metadata)

      controller.expects(:check_embargo_date_format).returns(nil)

      ModsAsset.expects(:find).with("_PID_").returns(mock_document)
      
      simple_request_params = {"asset"=>{
          "descMetadata"=>{
            "subject"=>{"0"=>"subject1", "1"=>"subject2", "2"=>"subject3"}
          }
        }
      }

      # Hull custom controller filters that should be called
      controller.expects(:update_set_membership)
      controller.expects(:validate_parameters)
      # testing :update_document in more granular way
      # controller.expects(:update_document).with(mock_document, update_hash)
      mock_document.expects(:respond_to?).with(:apply_additional_metadata).returns(false)
      mock_document.expects(:update_datastream_attributes).with(simple_request_params["asset"]).returns({"subject"=>{"2"=>"My Topic"}})
      mock_document.expects(:save)
      # controller.expects(:display_release_status_notice)

      put :update, {:id=>"_PID_"}.merge(simple_request_params)
    end


    #This and the following test check that the objects do not
    #change sets or permissions incorrectly..
    # This functionality should be moved into the model methods in the future
    describe "a published ukedt object" do
      include UserHelper
      before do
        @pid_id = "hull:3500"
        @hull_3500 = UketdObject.find(@pid_id)
      end

      it "should not be possible to set a blank structural set" do
      simple_request_params = {
        "asset"=>{
          "descMetadata"=>{
            :title_info_main_title=>{"0"=>"Main Title"},
            :person_0_namePart =>{"0"=>"Author's name"},
            :origin_info_date_issued =>{"0" => ''}
          }
        },
          "field_selectors"=>{
          "descMetadata"=>{
            "title_info_main_title"=>[":title_info", ":main_title"],
            "person_0_namePart"=>[{":person"=>0}, ":namePart"],
            "origin_info_date_issued"=>[":origin_info", ":date_issued"]
        }
        }, 
          "content_type"=>"uketd_object",
          "Structural Set" => [""],
          "Display Set" => ["info:fedora/hull:700"]
      }
        #Need to be authenticated as the CAT member
        cat_user_sign_in   
        put :update, {:id=>@hull_3500.pid}.merge(simple_request_params)
        @updated = UketdObject.find(@hull_3500.pid)

        flash.now[:error].should include("A structural set is required for published items")
        @updated.relationships(:is_member_of).should include("info:fedora/hull:3375")
      end

    end


    describe "an object that is in the Deleted queue" do
      include UserHelper
      before do
        @deleted_object_id = "hull:4775"
        @deleted_object = ExamPaper.find(@deleted_object_id)
        #Make sure that the set membership is reset to hull:4756
        @deleted_object.apply_set_membership(["info:fedora/hull:4756"])
        @deleted_object.save
      end

      it "should not be possible to update change the permissions based on structural set update" do
        #Will attempt to update the structural set to hull:3375...
        simple_request_params = {
          "content_type"=>"exam_paper",
          "Structural Set" => ["info:fedora/hull:3375"]
        }
  
        admin_user_sign_in

        put :update, {:id=>@deleted_object.pid}.merge(simple_request_params)        
        @deleted_object = ExamPaper.find(@deleted_object.pid)

        @deleted_object.relationships(:is_member_of).should include("info:fedora/hull:3375", "info:fedora/hull:deletedQueue")
        #Essential that the is_governed_by remains the deleteQueue..
        @deleted_object.relationships(:is_governed_by).should == ["info:fedora/hull:deletedQueue"]
        #...and that the rights remain the same as expected for the admin queue...
        @deleted_object.rightsMetadata.groups.should == {"admin"=>"edit"}
        @deleted_object.rightsMetadata.individuals.should == {}
      end
    end


    describe "a ukedt object" do
      include UserHelper
      before do
        ActiveFedora::RubydoraConnection.instance.connection
        @obj = UketdObject.new
        @obj.update_indexed_attributes({[{:person=>0}, :institution]=>"my org"}, :datastreams=>"descMetadata") #we need this or else we don't get a descMetadata ds (causes uketd_dc dissem error)
        @obj.dc.update_indexed_attributes([:dc_genre]=>"Thesis or Dissertation")
        #This object should be editable by the CAT group for this test...
        @obj.rightsMetadata.update_permissions({"group"=>{"contentAccessTeam"=>"discover","contentAccessTeam"=>"edit"}})
        @obj.save
      end
      it "should add the object to structural and display sets" do
        simple_request_params = {
          "asset"=>{
            "descMetadata"=>{
              :title_info_main_title=>{"0"=>"Main Title"},
              :person_0_namePart =>{"0"=>"Author's name"},
              :origin_info_date_issued =>{"0" => ''}
            }
          },
          "field_selectors"=>{
            "descMetadata"=>{
              "title_info_main_title"=>[":title_info", ":main_title"],
              "person_0_namePart"=>[{":person"=>0}, ":namePart"],
              "origin_info_date_issued"=>[":origin_info", ":date_issued"]
            }
          }, 
          "content_type"=>"uketd_object",
          "Structural Set" => ["info:fedora/hull:3375"],
          "Display Set" => ["info:fedora/hull:700"]
        }

        #Need to be authenticated as the CAT member
        cat_user_sign_in   
        put :update, {:id=>@obj.pid}.merge(simple_request_params)
        @updated = UketdObject.find(@obj.pid)
        @updated.relationships(:is_member_of).should include("info:fedora/hull:3375", "info:fedora/hull:700")
				@updated.relationships(:is_governed_by).should == ["info:fedora/hull:protoQueue"]
      end
      after do
        @obj.delete
      end
    end
  end
  
  describe "destroy" do
    before do
    	ActiveFedora::RubydoraConnection.instance.connection
     @obj = UketdObject.new
     @obj.update_indexed_attributes({[{:person=>0}, :institution]=>"my org"}, :datastreams=>"descMetadata") #we need this or else we don't get a descMetadata ds (causes uketd_dc dissem error)
     @obj.save
    end
    it "should delete the asset identified by pid" do
       delete(:destroy, :id => @obj.pid)
    end
  end
  
#  # withdraw is a conditional destroy, with the conditions dependant on the project requirements.
#  # Currently, the widthdraw method is an alias for destroy, should behave as such
#  describe "withdraw" do
#    it "should withdraw the asset identified by pid" do
#      mock_obj = mock("asset", :delete)
#      mock_obj.expects(:destroy_child_assets).returns([])
#      ActiveFedora::Base.expects(:load_instance_from_solr).with("__PID__").returns(mock_obj)
#      ActiveFedora::ContentModel.expects(:known_models_for).with(mock_obj).returns([HydrangeaArticle])
#      HydrangeaArticle.expects(:load_instance_from_solr).with("__PID__").returns(mock_obj)
#      delete(:withdraw, :id => "__PID__")
#    end
#  end
  
  
   
end
