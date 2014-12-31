module.exports = function(grunt) {

  require("matchdep").filterDev("grunt-*").forEach(grunt.loadNpmTasks);

  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),

    copy: {
      files: {
        cwd: '../static-resources/almond_uilib',
        src: '**/*',
        dest: './dist',
        expand: true
      }
    },
    uglify: {
      build: {
        files: {
          './dist/js/almondutils.min.js': ['./dist/js/almondutils.js'],
          './dist/js/fastclick.min.js': ['./dist/js/fastclick.js']
        }
      }
    },
    cssmin: {
      build: {
        expand: true,
        cwd: './dist/css/',
        src: ['*.css', '!*.min.css'],
        dest: './dist/css/',
        ext: '.min.css'
      }
    },
    compress: {
      almond: {
        options: {
          archive: '../app/src/staticresources/almond_uilib.resource',
          mode: 'zip'
        },
        files: [
            { expand: true, src: '**/*', cwd : "./dist" }
          ]
      }
    },
    clean : {
      almondCleanup : {
        src : [ './dist/']
      }
    },
    watch: {
      js: {
        files: ['../static-resources/almond_uilib/js/*.js'],
        tasks: ['uglify']
      },
      css: {
        files: ['../static-resources/almond_uilib/css/*.css'],
        tasks: ['cssmin']
      }
    }

  });

  // Default task(s).
  grunt.registerTask('default', ['copy', 'uglify', 'cssmin', 'compress', 'clean']);

};
