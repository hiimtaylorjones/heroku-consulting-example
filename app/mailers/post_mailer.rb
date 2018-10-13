class PostMailer < ApplicationMailer
  def create(post, email)
    @post = post

    mail to: email
  end
end
