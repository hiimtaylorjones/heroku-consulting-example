require 'test_helper'

class PostMailerTest < ActionMailer::TestCase

  setup do
    @post = posts(:one)
  end


  test "create" do
    mail = PostMailer.create(@post, "steve@apple.com")
    assert_equal "Create", mail.subject
    assert_equal ["steve@apple.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
