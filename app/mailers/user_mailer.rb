class UserMailer < ActionMailer::Base
end


class UserMailer < ActionMailer::Base
  default from: "#{ENV['GMAIL_USERNAME']}@gmail.com"
  def challenge(user, challenger, challenge)
    @user = user
    @challenger = challenger
    @challenge = challenge
    mail(:to => user.email,
         :subject => "You've been issued a challenge!") do |format|
      format.html
      format.text
    end
  end
end
