object @user

attributes :id
node(:reactions_count) {|obj| obj.stats.reactions_count }
node(:registered) {|obj| obj.stats.registered }
