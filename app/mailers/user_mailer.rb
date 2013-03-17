class UserMailer < ActionMailer::Base
end


class UserMailer < ActionMailer::Base
  default from: "#{ENV['GMAIL_USERNAME']}@gmail.com"
  def challenge(user, challenger, game)
    @user = user
    @challenger = challenger
    @game = game
    mail(:to => user.email,
         :subject => "You've been issued a challenge!") do |format|
      format.html if Rails.env.production?
      format.text if Rails.env.production?
    end
  end
end
