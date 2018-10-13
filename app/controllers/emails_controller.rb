class EmailsController < ApplicationController

  def new
    render :new
  end

  def create
    @post = Post.find params[:post_id]

    PostMailer.create(@post, params[:email]).deliver!
    redirect_to @post, notice: "Email sent!"
  end

end