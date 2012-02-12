require_relative '../teststrap'

describe Robin::Models::Player do
  describe "#send_email" do
    should "send email" do
      player = Robin::Models::Player.new username: 'player2', password: 'frog',
          email: 'a@b.co.uk'
      
      mock(Pony).mail to: 'a@b.co.uk', subject: 'hi',
                      body: <<END
Hi player2,

*message*

--- The Smash and Grab server

----------------------------

This is an automated message; please do not reply!
END
     
      player.send_mail 'hi', "*message*" 
    end
  end
end