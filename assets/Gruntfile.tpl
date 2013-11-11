module.exports = function(grunt) {

    var
    okColor = 'green',
    wrongColor = 'red',
    pendingColor = 'cyan',
    defaultColor = 'grey',

    DotColorizer = {
        line: '',

        is: function(line)
        {
            this.line = line;
            return this.isValidChar(0) && this.isValidChar(1) && this.isValidChar(2);
        },

        isValidChar: function(index)
        {
            return this.line.charAt(index) == '.' || this.line.charAt(index) == 'X' || this.line.charAt(index) == 'P' || this.line.charAt(index) == '';
        },

        colorize: function()
        {
            var line = '';
            for (var i=0,len=this.line.length; i < len; i++) {
                var ch = this.line[i];
                line += ch[this.getColor(ch)];
            }

            return line;
        },

        getColor: function(ch)
        {
            if (ch == '.') {
                return okColor;
            } else if (ch == 'X') {
                return wrongColor;
            } else if (ch == 'P') {
                return pendingColor;
            }

            return defaultColor;
        }
    },
    SummaryColorizer = {
        line: '',
        pattern: /(\d+ spec), (\d+ success), (\d+ pending), (\d+ failed), (\d+ expects)/,

        is: function(line)
        {
            this.line = line;
            return line.match(this.pattern);
        },

        colorize: function()
        {
            var parts = this.line.split(',');

            for (var i in parts) {
                var part = parts[i];
                parts[i] = part[this.getColor(part)];
            }

            return parts.join(','.grey);
        },

        getColor: function(part)
        {
            if (part.indexOf('success') != -1) {
                return okColor;
            } else if (part.indexOf('failed') != -1) {
                return wrongColor;
            } else if (part.indexOf('pending') != -1) {
                return pendingColor;
            }

            return defaultColor;
        }
    },
    DescriptiveColorizer = {
        line: '',
        matches: [],
        searchPattern: /(\s+)([X|P]: )/,
        replacePattern: /([X|P]: )/,

        is: function(line)
        {
            this.line = line;
            this.matches = this.line.match(this.searchPattern);
            return this.matches;
        },

        colorize: function()
        {
            this.line = this.line.replace(this.replacePattern, '');
            if (this.matches[2].indexOf('X') != -1) {
                return this.line[wrongColor];
            }

            return this.line[pendingColor];
        },
    },
    Highlighter = {
        line: '',
        lineIndex: 0,
        dotted: Object.create(DotColorizer),
        summary: Object.create(SummaryColorizer),
        descriptive: Object.create(DescriptiveColorizer),

        colorize: function()
        {
            return function(err, stdout, stderr) {
                stdout = stdout.split('\n');
                this.lineIndex = 1;
                for (var i in stdout) {
                    this.line = stdout[i];
                    this.process();
                    this.lineIndex++;
                }
            }.bind(this);
        },

        process: function()
        {
            if (this.lineIndex == 1 && this.dotted.is(this.line)) {
                this.line = this.dotted.colorize()+'\n';

            } else if (this.summary.is(this.line)) {
                this.line = this.summary.colorize();

            } else if (this.descriptive.is(this.line)) {
                this.line = this.descriptive.colorize();

            } else if (this.line.match(/\d+\)/)) {
                this.line = this.line[wrongColor];

            } else if (this.line == 'OK') {
                this.line = this.line[okColor];

            } else if (this.line == 'FAILED') {
                this.line = this.line[wrongColor];

            } else {
                this.line = this.line[defaultColor];
            }

            grunt.log.writeln(this.line);
        },
    },
    GrepValueChanger = {
        init: function(task)
        {
            if (!grunt.option('changed') || task.indexOf('watch:') == -1) {
                return;
            }

            this.registerToWatchTask(task.split(':')[1]);
        },

        registerToWatchTask: function(target)
        {
            var tester = Object.create(this);

            tester.target = target;
            grunt.event.on("watch", tester.listener.bind(tester));

            return tester;
        },

        listener: function(action, filepath, target)
        {
            if (!this.isListenedEvent(action, target)) {
                return;
            }
            grunt.log.writeln('');

            this.file = filepath;
            grunt.config.set('grep', '-g ' + this.grepValue());
        },

        isListenedEvent: function(action, target)
        {
            return action == 'changed' && target == this.target;
        },

        grepValue: function()
        {
            var
                prefix = '',
                suffix = '';

            if (this.file.match('Test.hx$')) {
                prefix = grunt.config.get('test');
                suffix = 'Test';
            } else {
                prefix = grunt.config.get('source');
            }

            suffix += '.hx';

            return this.file.substr(prefix.length + 1).replace(suffix, '').split('/').join('\\.');
        }
    },
    highlight = Highlighter.colorize(),
    grep = grunt.option('grep') ? '-g '+grunt.option('grep') : '',
    reporter = grunt.option('reporter') ? '-r '+grunt.option('reporter') : ''
    ;

    grunt.initConfig({
        testPath: '%test%',
        sourcePath: '%source%',
        paltforms: %platforms%,
        grep: grep,
        reporter: reporter,

        watch: {
            neko: {
                files: ['<%= testPath %>/**/*.hx', '<%= sourcePath %>/**/*.hx'],
                tasks: 'exec:test_neko'
            },
            cpp: {
                files: ['<%= testPath %>/**/*.hx', '<%= sourcePath %>/**/*.hx'],
                tasks: 'exec:test_cpp'
            },
        },

        exec: {
            test_neko: {
                command: 'haxelib run bdd test -p neko <%= grep %> <%= reporter %>',
                stdout: false,
                callback: highlight
            },
            test_cpp: {
                command: 'haxelib run bdd test -p cpp <%= grep %> <%= reporter %>',
                stdout: false,
                callback: highlight
            },
        }

    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-exec');

    GrepValueChanger.init(process.argv[2]);
};
