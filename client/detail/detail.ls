Template['detail'].helpers {
  vote: -> Votes.findOne (Session.get 'voteId')
  comment: -> Comments.find {voteId: (Session.get 'voteId')}
  orderToCategory: (order)->
    switch order
    |'categ0' => '商标设计'
    |'categ1' => '图标设计'
    |'categ2' => '软件设计'
    |'categ3' => '网页设计'
    |'categ4' => '服装设计'
    |'categ5' => '照片'
    |'categ6' => '其他'
  percentage: (num1, num2)->
    if (num1 / (num1 + num2) * 100) then (num1 / (num1 + num2) * 100) + '%'
    else "1%"
}

Template['detail'].events {
  'click img.firstImage': (event)!-> voteForImage choice = 'First'

  'click img.secondImage': (event)!-> voteForImage choice = 'Second'

  'submit form.deleteForm': (event)!->
    event.preventDefault!

    voteId = event.target.voteId.value
    firstImageId = event.target.firstImageId.value
    secondImageId = event.target.secondImageId.value

    Router.go '/'

    Votes.remove voteId
    Images.remove firstImageId
    Images.remove secondImageId

    Meteor.call 'removeBallots', {voteId: voteId}
    Meteor.call 'removeComments', {voteId: voteId}
    Meteor.call 'removeReports', {voteId: voteId}

  'submit form.reportForm': (event)!->
    event.preventDefault!

    voteId = event.target.voteId.value
    username = Meteor.user!.username

    if not Reports.find-one {voteId, username}
      Reports.insert {
        voteId: voteId
        username: username
      }

      Votes.update voteId, $inc: 'reportNum': 1

  'submit form.commentForm': (event)!->
    event.preventDefault!

    voteId = event.target.voteId.value

    Comments.insert {
      voteId: voteId
      username: Meteor.user!.username
      content: event.target.content.value
    }

    event.target.content.value = ''

  'submit form.statusForm': (event)!->
    event.preventDefault!

    voteId = event.target.voteId.value

    isOpen = Votes.findOne voteId .isOpen
    Votes.update voteId, $set: isOpen: !isOpen
}

voteForImage = (choice)!->
  voteId = Session.get 'voteId'
  user = Meteor.user!
  username =  user.username

  if not Votes.findOne voteId .isOpen then return

  if not Ballots.find-one {voteId, username}
    Ballots.insert {
      voteId: voteId
      choice: choice
      username: username
    }

    userGender = user.profile.gender
    userAge = ageToGroup user.profile.age
    userOccupation = user.profile.occupation

    setModifier = { $inc: {} }
    setModifier.$inc['numOfBallots'] = 1
    setModifier.$inc['numOf'+ choice] = 1
    setModifier.$inc['statisticsOf' + choice + '.gender.' + userGender] = 1
    setModifier.$inc['statisticsOf' + choice + '.age.' + userAge] = 1
    setModifier.$inc['statisticsOf' + choice + '.occupation.' + userOccupation] = 1

    Votes.update voteId, setModifier

ageToGroup = (age)->
  if 0 <= age <= 20 then 'group0'
  else if 21 <= age <= 30 then 'group1'
  else if 31 <= age <= 40 then 'group2'
  else if 41 <= age <= 50 then 'group3'
  else if age > 50 then then 'group4'

