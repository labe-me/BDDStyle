package cli.project;

import cli.helper.OpenFLParser;
import cli.project.Platform;

class OpenFLProject implements IProject
{
    private var platforms:Array<Platform>;
    private var requestedPlatforms:Array<String>;

    private var parser:OpenFLParser;

    public function new(parser:OpenFLParser, requestedPlatforms:Array<String>)
    {
        this.parser = parser;
        this.platforms = [];

        this.requestedPlatforms = requestedPlatforms.length == 0 ? [ 'neko' ] : requestedPlatforms;
        this.translateRequestedHaxePlatformsToOpenFL();
    }

    private function translateRequestedHaxePlatformsToOpenFL():Void
    {
        var system:String = Sys.systemName().toLowerCase();

        for (i in 0...this.requestedPlatforms.length) {
            switch (this.requestedPlatforms[i]) {
                case 'cpp': this.requestedPlatforms[i] = system;
                case 'neko': this.requestedPlatforms[i] = system + ' -neko';
                case 'swf': this.requestedPlatforms[i] = 'flash';
                case 'js': this.requestedPlatforms[i] = 'html5';
            }
        }
    }

    public function parse(content:String):Void
    {
        var platformData:PlatformData = this.parser.parse(content);

        for (platformName in requestedPlatforms) {
            platformData.name = platformName;
            this.platforms.push(new Platform(platformData));
        }
    }

    public function getPlatforms():Array<Platform>
    {
        return this.platforms;
    }

    public function run(platform:Platform):Void
    {

    }

    public function build(platform:Platform):Void
    {

    }
}
