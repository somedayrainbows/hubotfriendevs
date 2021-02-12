// Description:
//   Track arbitrary karma
//
// Dependencies:
//   None
//
// Configuration:
//   KARMA_ALLOW_SELF
//
// Commands:
//   karmabot create @Slackname - create karma keeping for a slack user
//   karmabot empty @Slackname - empty someone's total karma
//   @Slackname++ to give someone some karma
//   @Slackname-- to take away someone's karma
//   karmabot @Slackname - check someone's karma (if @Slackname is omitted, show the top 5)
//   karmabot best - show the five with the most karma
//   karmabot least - show the five with the least karma

class Karma {

  constructor(robot) {
    this.robot = robot;
    this.cache = {};

    this.increment_responses = [
      "+1!", "got some karma! Woohoo!", "is so loved. You go, girl.", "leveled up! Yassss!"
    ];

    this.decrement_responses = [
      "just lost some karma! So sad.", "has been downgraded.", "-1 karma point. Ouch!"
    ];

    this.robot.brain.on('loaded', () => {
      if (this.robot.brain.data.karma) {
        return this.cache = this.robot.brain.data.karma;
      }
    });
  }

  exists(slackname) {
    // Object.keys(this.cache).includes(slackname);
    return (slackname in this.cache)
  }

  create(slackname) {
    if (this.cache[slackname] == null) { this.cache[slackname] = 0; }
    return this.robot.brain.data.karma = this.cache;
  }

  delete(slackname) {
    delete this.cache[slackname];
    return this.robot.brain.data.karma = this.cache;
  }

  increment(slackname) {
    if (this.cache[slackname] == null) { this.cache[slackname] = 0; }
    this.cache[slackname] += 1;
    return this.robot.brain.data.karma = this.cache;
  }

  decrement(slackname) {
    if (this.cache[slackname] == null) { this.cache[slackname] = 0; }
    this.cache[slackname] -= 1;
    return this.robot.brain.data.karma = this.cache;
  }

  adjust(slackname, amount) {
    if (this.cache[slackname] == null) { this.cache[slackname] = 0; }
    this.cache[slackname] += amount;
    return this.robot.brain.data.karma = this.cache;
  }

  incrementResponse() {
    return this.increment_responses[Math.floor(Math.random() * this.increment_responses.length)];
  }

  decrementResponse() {
    return this.decrement_responses[Math.floor(Math.random() * this.decrement_responses.length)];
  }

  selfDeniedResponses(name) {
    return this.self_denied_responses = [
      "You can't self-award karma.",
      "Um, no.",
      `Nope. Try getting someone else to give you some karma, ${name}.`
    ];
  }

  get(slackname) {
    const k = this.cache[slackname] ? this.cache[slackname] : 0;
    return k;
  }

  sort() {
    const s = [];
    for (let key in this.cache) {
      const val = this.cache[key];
      s.push({ name: key, karma: val });
    }
    return s.sort((a, b) => b.karma - a.karma);
  }

  top(n) {
    if (n == null) { n = 10; }
    const sorted = this.sort();
    return sorted.slice(0, n);
  }

  bottom(n) {
    if (n == null) { n = 10; }
    const sorted = this.sort();
    return sorted.slice(-n).reverse();
  }

  cleanSubject(subject) {
    // remove any prefix characters (e.g. @, ", ', etc.)
    return subject.trim().replace(/^[^a-z]+/, '').replace(/:$/, '');
  }
}

module.exports = (robot) => {
  const karma = new Karma(robot);
  const allow_self = process.env.KARMA_ALLOW_SELF || false;

  robot.hear(/(@[^@+:]+|[^-+:\s]*)[:\s]*(\+\+|--)/g, (msg) => {
    const output = [];
    for (let subject of Array.from(msg.match)) {
      const user = msg.message.user.name.toLowerCase();
      subject = subject.trim();
      const increasing = subject.slice(-2) === "++";
      subject = karma.cleanSubject(subject.slice(0, +-3 + 1 || undefined).toLowerCase());
      if (subject === '') {
        continue;
      }

      if ((allow_self === false) && (user === subject)) {
        output.push(msg.random(karma.selfDeniedResponses(msg.message.user.name)));
        continue;
      }

      if (!karma.exists(subject)) {
        output.push(`Karma does not exist for '${subject}'. Use \`${robot.name} create ${subject}\` to make it right.`);
        continue;
      }

      if (increasing) {
        karma.increment(subject);
        output.push(`${subject} ${karma.incrementResponse()} (Karma: ${karma.get(subject)})`);
      } else {
        karma.decrement(subject);
        output.push(`${subject} ${karma.decrementResponse()} (Karma: ${karma.get(subject)})`);
      }
    }
    if (output.length > 0) {
      return msg.send(output.join('\n'));
    }
  });

  robot.respond(/create ?(@[^@+:]+|[^-+:\s]*)$/i, (msg) => {
    const subject = karma.cleanSubject(msg.match[1].toLowerCase());

    if (karma.exists(subject)) {
      msg.send(`Karma already exists for ${subject}`);
      return;
    }

    karma.create(subject);
    return msg.send(`${subject} is now ready to receive karma! Use \`${subject}++\` and \`${subject}--\` to give and take karma.`);
  });

  robot.respond(/empty ?(@[^@+:]+|[^-+:\s]*)$/i, (msg) => {
    const subject = karma.cleanSubject(msg.match[1].toLowerCase());
    karma.delete(subject);
    return msg.send(`${subject}'s karma has been scattered to the winds.`);
  });

  robot.respond(/best$/i, (msg) => {
    const verbiage = ["The Best"];
    const iterable = karma.top();
    for (let rank = 0; rank < iterable.length; rank++) {
      const item = iterable[rank];
      verbiage.push(`${rank + 1}. ${item.name} - ${item.karma}`);
    }
    return msg.send(verbiage.join("\n"));
  });

  robot.respond(/least$/i, (msg) => {
    const verbiage = ["The Least"];
    const iterable = karma.bottom();
    for (let rank = 0; rank < iterable.length; rank++) {
      const item = iterable[rank];
      verbiage.push(`${rank + 1}. ${item.name} - ${item.karma}`);
    }
    return msg.send(verbiage.join("\n"));
  });

  return robot.respond(/(@[^@+:]+|[^-+:\s]*)$/i, (msg) => {
    const match = karma.cleanSubject(msg.match[1].toLowerCase());
    if ((match !== "best") && (match !== "least") && (match.substr(0, 6) !== "create") && (match.substr(0, 5) !== "empty")) {
      if (karma.exists(match)) {
        return msg.send(`\"${match}\" has ${karma.get(match)} karma.`);
      } else {
        if (match === 'ping') {
          return;
        }
        return msg.send(`Karma does not exist for '${match}'. Use \`${robot.name} create ${match}\` to make it right.`);
      }
    }
  });
};
