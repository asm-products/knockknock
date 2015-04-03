var _ = require('cloud/underscore-min');

Parse.Cloud.beforeSave(Parse.User, function (request, response) {
  // Save lower-case version of full name for searching
  // as Parse doesn't support case-insensitive searches.

  var fullName = request.object.get('fullName');
  if (fullName) {
    request.object.set('fullNameLC', fullName.toLowerCase());
  }

  // Same for twitter screen names.

  var twScreenName = request.object.get('twScreenName');
  if (twScreenName) {
    request.object.set('twScreenNameLC', twScreenName.toLowerCase());
  }

  // Set default options for new accounts

  if (request.object.isNew()) {
    request.object.set("pushReceiveKnock", true);
    request.object.set("pushCollageComplete", true);
    request.object.set("pushFriendRequests", true);
    request.object.set("hasUpgraded", false);
  }

  response.success();
});

// Input: requestorID: objectID of user that requested to be friends with calling user.

Parse.Cloud.define('becomeFriends', function (request, response) {
  if (!request.user) {
    response.error('user required');
    return;
  }

  Parse.Cloud.useMasterKey();

  var caller = request.user,
  query = new Parse.Query(Parse.User);

  query.get(request.params.requestorID).then(function (requestor) {
    // caller adds requestor as a friend

    var friends = caller.relation('friends');
    friends.add(requestor);
    var promises = [ caller.save() ];

    // requestor adds caller as a friend

    friends = requestor.relation('friends');
    friends.add(caller);
    promises.push(requestor.save());

    // remove friend requests by these two on each other

    var FriendRequest = Parse.Object.extend('FriendRequest');

    var q1 = new Parse.Query(FriendRequest);
    q1.equalTo('sourceUser', caller);
    q1.equalTo('targetUser', requestor);

    var q2 = new Parse.Query(FriendRequest);
    q2.equalTo('sourceUser', requestor);
    q2.equalTo('targetUser', caller);

    var q = Parse.Query.or(q1, q2);
    q.find().then(function (results) {
      for (var i = 0, N = results.length; i < N; ++i) {
        promises.push(results[i].destroy());
      }

      // And wait for it all to be done.

      Parse.Promise.when(promises).then(function () {
        response.success();
      }, function (error) {
        response.error(error.message);
      });
    }, function (error) {
      response.error(error.message);
    });
  }, function (error) {
    response.error(error.message);
  });
});

// Each user always subscribes to their own user push channel which has a
// channel name of u$(Parse.User.id)

function pushChannels(users, settingName) {
  return _.chain(users)
  .filter(function (user) { return !!user.get(settingName); })
  .map(function (user) { return 'u' + user.id; })
  .value();
}

// Tell the target user that the source user (the calling user) has requested
// to be their friend in this app.  Get settings of the target user.  If they
// have pushFriendRequests disabled, do NOT send them a push notification.

Parse.Cloud.afterSave("FriendRequest", function (request) {
  var promises = [
    new Parse.Query(Parse.User).get(request.object.get('sourceUser').id),
    new Parse.Query(Parse.User).get(request.object.get('targetUser').id)
  ];

  Parse.Promise.when(promises).then(function (sourceUser, targetUser) {
    for (var i = 0; i < arguments.length; ++i)
    console.log(arguments[i]);

    if (!!targetUser.get('pushFriendRequests')) {
      Parse.Push.send({
        channels: [ 'u' + targetUser.id ],
        data: {
          alert: sourceUser.get('fullName') + ' wants to be your friend.',
          badge: 'Increment',
          type: 'friendRequest',
          sourceUserID: request.user.id
        }
      }, {
        success: function () {},
        error: function (error) {
          console.error('failed to send push notification: ' + error.message);
        }
      });
    }
  });
});

Parse.Cloud.beforeSave('Collage', function (request, response) {
  var collage = request.object;

  if (!collage.isNew()) {
    response.success();
    return;
  }

  // Generate random assignments for photos added to the collage.  These are
  // not referenced until the final collage is rendered on each client.  Each
  // client sorts the photos of the collage by date-created/added.  To draw
  // the full collage, the sub-images are drawn in the cell corresponding to
  // the index in this array.  Oldest image in collage gets index 0, next
  // oldest gets index 1, etc.

  var size = +collage.get('size') || 2;

  collage.set('photoIndexes', _.shuffle(_.range(size * size)));

  // Generate background colors for each image cell in the 2D grid collage.
  // Sometimes a collage's invited users will not respond or will pass/reject
  // the invitation, leaving blanks in the collage. We fill those empty
  // indexes with symbolic colors. Actually, we'll just assign random
  // symbolic colors to all indexes. The actual colors are defined in the
  // client app.

  assignBackgroundColors(collage);

  response.success();
});

function assignBackgroundColors(collage) {
  var size = +collage.get('size'),
  availColors = [ 'pink', 'yellow', 'blue', 'green' ],
  N = availColors.length;

  while (true) {
    var bgcolors = [],
    prev;

    // Pick randomly from available colors. Do not allow the same color to be used
    // twice consecutively.

    for (var i=0; i < size*size; ++i) {
      var bgcolor;

      do {
        bgcolor = availColors[Math.floor(Math.random() * N)];
      } while (bgcolor == prev);

      prev = bgcolor;
      bgcolors.push(bgcolor);
    }

    // Make sure all the colors were used at least once.

    var hist = {};
    for (var i=0; i<bgcolors.length; ++i) {
      var key = bgcolors[i];
      hist[key] = (hist[key] || 0) + 1;
    }

    if (Object.getOwnPropertyNames(hist).length == N) {
      collage.set('backgroundColors', bgcolors);
      return;
    }
  }
}

Parse.Cloud.define('sendInvites', function (request, response) {
  var collageId = request.params.collageId;
  new Parse.Query('Collage').include('invitees').get(collageId).then(function (collage) {
    if (!collage) {
      response.error('No such collage');
      return;
    }

    // This is a new collage. Send out invitations to invitees.  But, respect
    // push settings of each user.  Invitees is just an array of pointers to
    // User objects. We have to fetch the full User objects to get their
    // settings.

    var invitees = collage.get('invitees'),
    userQuery = new Parse.Query(Parse.User);

    userQuery.containedIn('objectId', _.map(invitees, function (user) {
      return user.id;
    }));

    userQuery.find().then(function (users) {
      Parse.Push.send({
        channels: pushChannels(users, 'pushReceiveKnock'),
        data: {
          alert: "see who's there",
          sound: "knock.caf",

          // NB: no badge:'Increment' here since it's so time-limited and
          // there is nowhere in the app to view-ongoing-knocks.

          type: 'invite',
          collageID: collage.id
        }
      }, {
        success: function () {
          response.success();
        },
        error: function (error) {
          console.error('failed to send push notification: ' + error.message);
          response.error(error.message);
        }
      });
    });

  }, function (error) {
    response.error(error.message);
  });
});

// Add the author of the photo as a participant of the collage.

Parse.Cloud.afterSave("CollagePhoto", function (request) {
  var Collage = Parse.Object.extend("Collage"),
  query = new Parse.Query(Collage);

  query.get(request.object.get('collage').id, {
    success: function (collage) {
      if (!request.object.existed()) {
        collage.addUnique('participants', request.user);
        collage.save();
      }
    },
    error: function(object, error) {}
  });
});

// The initiator calls this after 60s have elapsed in order to finalize/stop
// the collage creation process for a single collage. The idea is to make it
// enticing to join in on collage creation by scoping its creation to a finite
// window of time.
//
// Input: collageID: The collage to finalize.
// Side effects: All participants receive a push notification (if setting is allowed)

Parse.Cloud.define('finalizeCollage', function (request, response) {
  var collageID = request.params.collageID;

  var query = new Parse.Query('Collage').include('participants').get(collageID, {
    success: function (collage) {
      collage.set('completedAt', new Date());

      collage.save().then(function () {
        var participants = collage.get('participants') || [];

        if (participants.length == 1) {
          // Only the initiator participated.
          // Thus, do not send out the notice that "we" have
          // created a knock/collage.

          response.success(participants.length);
          return;
        }

        var userQuery = new Parse.Query(Parse.User)
        .containedIn('objectId', _.map(participants, function (user) {
          return user.id;
        }))
        .find().then(function (users) {
          Parse.Push.send({
            channels: pushChannels(users, 'pushCollageComplete'),
            data: {
              alert: 'Knock complete!',
              badge: 'Increment',
              type: 'knockComplete',
              collageID: collage.id
            }
          }, {
            success: function () {
              response.success();
            },
            error: function (error) {
              console.error('failed to send push notification: ' + error.message);
              response.error(error.message);
            }
          });
        }, function (error) {
          response.error(error.message);
        });
      }, function (error) {
        response.error(error.message);
      });
    },
    error: function(object, error) {
      response.error(error.message);
    }
  });
});
