package cli.project.openfl;

import cli.project.Platform;

class Project implements cli.project.IProject
{
    private var platforms:Array<Platform>;
    private var requestedPlatforms:Array<String>;
    private var file:String;

    private var parser:Parser;
    private var compiled:Compiled;
    private var process:cli.helper.Process;

    public function new(parser:Parser, compiled:Compiled, process:cli.helper.Process, requestedPlatforms:Array<String>)
    {
        this.parser = parser;
        this.process = process;
        this.compiled = compiled;
        this.platforms = [];

        this.requestedPlatforms = requestedPlatforms.length == 0 ? [ 'neko' ] : requestedPlatforms;
        this.translateRequestedHaxePlatformsToOpenFL();
    }

    private function translateRequestedHaxePlatformsToOpenFL():Void
    {
        for (i in 0...this.requestedPlatforms.length) {
            this.requestedPlatforms[i] = this.compiled.translateHaxePlatform(this.requestedPlatforms[i]);
        }
    }

    public function parse(content:String, file:String=''):Void
    {
        this.file = file;

        var platformData:PlatformData = this.parser.parse(content);
        var platformReplacerEReg:EReg = ~/%platform%/;
        var splittedPlatformName:Array<String> = [];

        for (platformName in requestedPlatforms) {
            splittedPlatformName = platformName.split(' ');

            platformData.name = platformName;
            platformData.compiledPath = platformReplacerEReg.replace(platformData.compiledPath, splittedPlatformName[0]);
            this.platforms.push(new Platform(platformData));
        }
    }

    public function getPlatforms():Array<Platform>
    {
        return this.platforms;
    }

    public function run(platform:Platform, args:cli.helper.Args):Int
    {
        var runnable:cli.project.Runnable = this.compiled.getRunnable(platform, args);
        if (runnable.command == '%DEFAULT%') {
            this.process.runWithDefault(runnable.args[0]);
            return 0;
        } else if (runnable.command != '') {
            return this.process.run(runnable.command, runnable.args);
        }

        return this.process.run('openfl', this.getArgument('run', platform));
    }

    private function getArgument(command:String, platform:Platform):Array<String>
    {
        return [command, this.file].concat(platform.name.split(' '));
    }

    public function build(platform:Platform):Void
    {
        this.process.run('openfl', this.getArgument('build', platform));
    }
}
