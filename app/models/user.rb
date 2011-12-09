class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
 include Hydra::User

 before_save :get_user_attributes
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
#  devise :database_authenticatable, :registerable,
 #         :recoverable, :rememberable, :trackable, :validatable

  devise :cas_authenticatable
  # Setup accessible (or protected) attributes for your model
  #attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :username
  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    username
  end

 def get_user_attributes
    self.email = "test.test@hull.ac.uk"
	
    person = ActiveRecord::Base.connection.select_one('SELECT * FROM person WHERE user_name=' + username )
		
		self.email = person["EmailAddress"]
    self.user_type = person["type"]
  end
  
end
