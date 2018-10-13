Author.destroy_all

100.times do
  Author.create!({ name: FFaker::Name.name, email: FFaker::Internet.email })
end


# Posts
Post.destroy_all
authors = Author.all

1_000.times do

  post = Post.create!({
    title: FFaker::Lorem.words.join(" ").titleize,
    body: FFaker::Lorem.paragraphs.join("\n\n"),
    author: authors.sample
  })

  10.times do
    Comment.create!({
      name: FFaker::Name.name,
      body: FFaker::Lorem.paragraph,
      post: post
    })
  end

end