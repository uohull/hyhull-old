class UketddcEtd < ActiveFedora::NokogiriDatastream       
  include Hydra::CommonModsIndexMethods

  set_terminology do |t|
    t.root("path"=>"uketddc",
		:namespace_prefix=>"uketd_dc",
		"xmlns:uketd_dc"=>"http://naca.central.cranfield.ac.uk/ethos-oai/2.0/",
        "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
		"xmlns:dcterms"=>"http://purl.org/dc/terms/",
		"xmlns:uketdterms"=>"http://naca.central.cranfield.ac.uk/ethos-oai/terms/",
 		"xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance")
    t.title(:namespace_prefix=>"dc", :path=>"title")
    t.author(:namespace_prefix=>"dc", :path=>"creator")
    t.advisor(:namespace_prefix=>"uketdterms", :path=>"advisor")
    t.grant_number(:namespace_prefix=>"uketdterms", :path=>"grantnumber")
    t.issued(:namespace_prefix=>"dcterms", :path=>"issued")
    t.sponsor(:namespace_prefix=>"uketdterms", :path=>"sponsor")
    t.subject(:namespace_prefix=>"dc", :path=>"subject")
    t.abstract(:namespace_prefix=>"dcterms", :path=>"abstract")
    t.date(:namespace_prefix=>"dc", :path=>"date")
    t.format(:namespace_prefix=>"dc", :path=>"format", "xsi:type"=>"dcterms:IMT")
    t.language(:namespace_prefix=>"dc", :path=>"language", "xsi:type"=>"dcterms:ISO6392")
    t.object_type(:namespace_prefix=>"dc", :path=>"type")
    t.qualification_level(:namespace_prefix=>"uketdterms", :path=>"qualificationlevel")
    t.qualification_name(:namespace_prefix=>"uketdterms", :path=>"qualificationname")
    t.institution(:namespace_prefix=>"uketdterms", :path=>"institution")
    t.department(:namespace_prefix=>"uketdterms", :path=>"department")
    t.rights(:namespace_prefix=>"dc", :path=>"rights")
    t.referenced_by(:namespace_prefix=>"dcterms", :path=>"isReferencedBy", "xsi:type"=>"dcterms:URI")
    t.identifier(:namespace_prefix=>"dc", :path=>"identifier", "xsi:type"=>"dcterms:URI")
  end
  
    # accessor :title, :term=>[:mods, :title_info, :main_title]
    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.uketddc(:namespace_prefix=>"uketd_dc",
			"xmlns:uketd_dc"=>"http://naca.central.cranfield.ac.uk/ethos-oai/2.0/",
        	"xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
			"xmlns:dcterms"=>"http://purl.org/dc/terms/",
			"xmlns:uketdterms"=>"http://naca.central.cranfield.ac.uk/ethos-oai/terms/",
 			"xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance") {             
			xml.title(:namespace_prefix=>"dc") 
			xml.creator(:namespace_prefix=>"dc")
            xml.advisor(:namespace_prefix=>"uketdterms")
            xml.grantnumber(:namespace_prefix=>"uketdterms")
			xml.issued(:namespace_prefix=>"dcterms")
			xml.sponsor(:namespace_prefix=>"uketdterms")
			xml.subject(:namespace_prefix=>"dc")
			xml.abstract(:namespace_prefix=>"dcterms")
			xml.date(:namespace_prefix=>"dc")
			xml.format(:namespace_prefix=>"dc", "xsi:type"=>"dcterms:IMT")
			xml.language(:namespace_prefix=>"dc", "xsi:type"=>"dcterms:ISO6392")
			xml.object_type(:namespace_prefix=>"dc",:path=>"type")
			xml.qualificationlevel(:namespace_prefix=>"uketdterms")
			xml.qualificationname(:namespace_prefix=>"uketdterms")
			xml.institution(:namespace_prefix=>"uketdterms")
			xml.department(:namespace_prefix=>"uketdterms")
			xml.rights(:namespace_prefix=>"dc")
            xml.isReferencedBy(:namespace_prefix=>"dcterms", "xsi:type"=>"dcterms:URI")
			xml.identifier(:namespace_prefix=>"dc", "xsi:type"=>"dcterms:URI")
        }
      end
      return builder.doc
    end    
    
    # Generates a new Person node
    def self.person_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.name(:type=>"personal") {
          xml.namePart
          xml.role {
            xml.roleTerm(:type=>"text")
          }
        }
      end
      return builder.doc.root
    end
   
    # Inserts a new contributor (mods:name) into the mods document
    # creates contributors of type :person, :organization, or :conference
    def insert_contributor(type, opts={})
      case type.to_sym 
      when :person
        node = HullModsEtd.person_template
        nodeset = self.find_by_terms(:person)
      else
        ActiveFedora.logger.warn("#{type} is not a valid argument for HullModsEtd.insert_contributor")
        node = nil
        index = nil
      end
      
      unless nodeset.nil?
        if nodeset.empty?
          self.ng_xml.root.add_child(node)
          index = 0
        else
          nodeset.after(node)
          index = nodeset.length
        end
        self.dirty = true
      end
      
      return node, index
    end
    
    # Remove the contributor entry identified by @contributor_type and @index
    def remove_contributor(contributor_type, index)
      self.find_by_terms( {contributor_type.to_sym => index.to_i} ).first.remove
      self.dirty = true
    end
    
    def self.common_relator_terms
       {"aut" => "Author",
        "clb" => "Collaborator",
        "com" => "Compiler",
        "ctb" => "Contributor",
        "cre" => "Creator",
        "edt" => "Editor",
        "ill" => "Illustrator",
        "oth" => "Other",
        "trl" => "Translator",
        }
    end
    
    def self.person_relator_terms
      {"aut" => "Author",
       "clb" => "Collaborator",
       "com" => "Compiler",
       "cre" => "Creator",
       "ctb" => "Contributor",
       "edt" => "Editor",
       "ill" => "Illustrator",
       "res" => "Researcher",
       "rth" => "Research team head",
       "rtm" => "Research team member",
       "trl" => "Translator"
       }
    end
    
    def self.conference_relator_terms
      {
        "hst" => "Host"
      }
    end
    
    def self.organization_relator_terms
      {
        "fnd" => "Funder",
        "hst" => "Host"
      }
    end
    
    def self.dc_relator_terms
       {"acp" => "Art copyist",
        "act" => "Actor",
        "adp" => "Adapter",
        "aft" => "Author of afterword, colophon, etc.",
        "anl" => "Analyst",
        "anm" => "Animator",
        "ann" => "Annotator",
        "ant" => "Bibliographic antecedent",
        "app" => "Applicant",
        "aqt" => "Author in quotations or text abstracts",
        "arc" => "Architect",
        "ard" => "Artistic director ",
        "arr" => "Arranger",
        "art" => "Artist",
        "asg" => "Assignee",
        "asn" => "Associated name",
        "att" => "Attributed name",
        "auc" => "Auctioneer",
        "aud" => "Author of dialog",
        "aui" => "Author of introduction",
        "aus" => "Author of screenplay",
        "aut" => "Author",
        "bdd" => "Binding designer",
        "bjd" => "Bookjacket designer",
        "bkd" => "Book designer",
        "bkp" => "Book producer",
        "bnd" => "Binder",
        "bpd" => "Bookplate designer",
        "bsl" => "Bookseller",
        "ccp" => "Conceptor",
        "chr" => "Choreographer",
        "clb" => "Collaborator",
        "cli" => "Client",
        "cll" => "Calligrapher",
        "clt" => "Collotyper",
        "cmm" => "Commentator",
        "cmp" => "Composer",
        "cmt" => "Compositor",
        "cng" => "Cinematographer",
        "cnd" => "Conductor",
        "cns" => "Censor",
        "coe" => "Contestant -appellee",
        "col" => "Collector",
        "com" => "Compiler",
        "cos" => "Contestant",
        "cot" => "Contestant -appellant",
        "cov" => "Cover designer",
        "cpc" => "Copyright claimant",
        "cpe" => "Complainant-appellee",
        "cph" => "Copyright holder",
        "cpl" => "Complainant",
        "cpt" => "Complainant-appellant",
        "cre" => "Creator",
        "crp" => "Correspondent",
        "crr" => "Corrector",
        "csl" => "Consultant",
        "csp" => "Consultant to a project",
        "cst" => "Costume designer",
        "ctb" => "Contributor",
        "cte" => "Contestee-appellee",
        "ctg" => "Cartographer",
        "ctr" => "Contractor",
        "cts" => "Contestee",
        "ctt" => "Contestee-appellant",
        "cur" => "Curator",
        "cwt" => "Commentator for written text",
        "dfd" => "Defendant",
        "dfe" => "Defendant-appellee",
        "dft" => "Defendant-appellant",
        "dgg" => "Degree grantor",
        "dis" => "Dissertant",
        "dln" => "Delineator",
        "dnc" => "Dancer",
        "dnr" => "Donor",
        "dpc" => "Depicted",
        "dpt" => "Depositor",
        "drm" => "Draftsman",
        "drt" => "Director",
        "dsr" => "Designer",
        "dst" => "Distributor",
        "dtc" => "Data contributor ",
        "dte" => "Dedicatee",
        "dtm" => "Data manager ",
        "dto" => "Dedicator",
        "dub" => "Dubious author",
        "edt" => "Editor",
        "egr" => "Engraver",
        "elg" => "Electrician ",
        "elt" => "Electrotyper",
        "eng" => "Engineer",
        "etr" => "Etcher",
        "exp" => "Expert",
        "fac" => "Facsimilist",
        "fld" => "Field director ",
        "flm" => "Film editor",
        "fmo" => "Former owner",
        "fpy" => "First party",
        "fnd" => "Funder",
        "frg" => "Forger",
        "gis" => "Geographic information specialist ",
        "grt" => "Graphic technician",
        "hnr" => "Honoree",
        "hst" => "Host",
        "ill" => "Illustrator",
        "ilu" => "Illuminator",
        "ins" => "Inscriber",
        "inv" => "Inventor",
        "itr" => "Instrumentalist",
        "ive" => "Interviewee",
        "ivr" => "Interviewer",
        "lbr" => "Laboratory ",
        "lbt" => "Librettist",
        "ldr" => "Laboratory director ",
        "led" => "Lead",
        "lee" => "Libelee-appellee",
        "lel" => "Libelee",
        "len" => "Lender",
        "let" => "Libelee-appellant",
        "lgd" => "Lighting designer",
        "lie" => "Libelant-appellee",
        "lil" => "Libelant",
        "lit" => "Libelant-appellant",
        "lsa" => "Landscape architect",
        "lse" => "Licensee",
        "lso" => "Licensor",
        "ltg" => "Lithographer",
        "lyr" => "Lyricist",
        "mcp" => "Music copyist",
        "mfr" => "Manufacturer",
        "mdc" => "Metadata contact",
        "mod" => "Moderator",
        "mon" => "Monitor",
        "mrk" => "Markup editor",
        "msd" => "Musical director",
        "mte" => "Metal-engraver",
        "mus" => "Musician",
        "nrt" => "Narrator",
        "opn" => "Opponent",
        "org" => "Originator",
        "orm" => "Organizer of meeting",
        "oth" => "Other",
        "own" => "Owner",
        "pat" => "Patron",
        "pbd" => "Publishing director",
        "pbl" => "Publisher",
        "pdr" => "Project director",
        "pfr" => "Proofreader",
        "pht" => "Photographer",
        "plt" => "Platemaker",
        "pma" => "Permitting agency",
        "pmn" => "Production manager",
        "pop" => "Printer of plates",
        "ppm" => "Papermaker",
        "ppt" => "Puppeteer",
        "prc" => "Process contact",
        "prd" => "Production personnel",
        "prf" => "Performer",
        "prg" => "Programmer",
        "prm" => "Printmaker",
        "pro" => "Producer",
        "prt" => "Printer",
        "pta" => "Patent applicant",
        "pte" => "Plaintiff -appellee",
        "ptf" => "Plaintiff",
        "pth" => "Patent holder",
        "ptt" => "Plaintiff-appellant",
        "rbr" => "Rubricator",
        "rce" => "Recording engineer",
        "rcp" => "Recipient",
        "red" => "Redactor",
        "ren" => "Renderer",
        "res" => "Researcher",
        "rev" => "Reviewer",
        "rps" => "Repository",
        "rpt" => "Reporter",
        "rpy" => "Responsible party",
        "rse" => "Respondent-appellee",
        "rsg" => "Restager",
        "rsp" => "Respondent",
        "rst" => "Respondent-appellant",
        "rth" => "Research team head",
        "rtm" => "Research team member",
        "sad" => "Scientific advisor",
        "sce" => "Scenarist",
        "scl" => "Sculptor",
        "scr" => "Scribe",
        "sds" => "Sound designer",
        "sec" => "Secretary",
        "sgn" => "Signer",
        "sht" => "Supporting host",
        "sng" => "Singer",
        "spk" => "Speaker",
        "spn" => "Sponsor",
        "spy" => "Second party",
        "srv" => "Surveyor",
        "std" => "Set designer",
        "stl" => "Storyteller",
        "stm" => "Stage manager",
        "stn" => "Standards body",
        "str" => "Stereotyper",
        "tcd" => "Technical director",
        "tch" => "Teacher",
        "ths" => "Thesis advisor",
        "trc" => "Transcriber",
        "trl" => "Translator",
        "tyd" => "Type designer",
        "tyg" => "Typographer",
        "vdg" => "Videographer",
        "voc" => "Vocalist",
        "wam" => "Writer of accompanying material",
        "wdc" => "Woodcutter",
        "wde" => "Wood -engraver",
        "wit" => "Witness"}
      end
    
      def self.valid_child_types
        ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
      end

      def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        solr_doc.merge!("object_type_facet"=> "Thesis or dissertation")
        solr_doc
      end

end
