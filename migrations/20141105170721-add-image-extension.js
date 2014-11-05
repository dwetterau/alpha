"use strict";

module.exports = {
  up: function(migration, DataTypes, done) {
    // add altering commands here, calling 'done' when finished
    migration.addColumn(
      "Images",
      "extension",
      {
        type: DataTypes.STRING,
        defaultValue: '.jpg'
      }
    ).complete(function(err) {
      if (err) {
        console.log("There was an error: ", err);
      } else {
        console.log("Finished successfully.");
      }
      done(err);
    });
  },

  down: function(migration, DataTypes, done) {
    // add reverting commands here, calling 'done' when finished
    migration.removeColumn("Images", "extension").complete(function(err) {
      if (err) {
        console.log("There was an error: ", err);
      } else {
        console.log("Finished successfully.");
      }
      done(err);
    });
  }
};
