
void Debug(string text, int color = 0)
{
    string[] path = getCurrentScriptName().split("/");
    string script = path[path.size()-1];
    print(script+" | ---> | "+text, colors[color]);
}

SColor[] colors = {
    0xFF8BFF60,
    0xFFFFC760,
    0xFF60B7FF,
    0xFFFF6060
};