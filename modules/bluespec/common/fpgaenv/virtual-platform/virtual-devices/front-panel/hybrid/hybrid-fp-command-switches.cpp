
FRONT_PANEL_COMMAND_SWITCHES FRONT_PANEL_COMMAND_SWITCHES::instance;

FRONT_PANEL_COMMAND_SWITCHES::FRONT_PANEL_COMMAND_SWITCHES() :
    COMMAND_SWITCH_OPTIONAL_STRING("showfp")
{
}

FRONT_PANEL_COMMAND_SWITCHES::~FRONT_PANEL_COMMAND_SWITCHES()
{
}

int
FRONT_PANEL_COMMAND_SWITCHES::ProcessSwitch(char *switch_arg, char *error_buff)
{
    if (switch_arg == NULL)
    {
        showFrontPanel = true;
        showLEDsOnStdOut = false;
        return true;
    }
    else if (strcmp(switch_arg, "stdout") == 0)
    {
        showFrontPanel = false;
        showLEDsOnStdOut = true;
        return true;
    }
    else if (strncmp(switch_arg, "no", 2) == 0)
    {
        showFrontPanel = false;
        showLEDsOnStdOut = false;
        return true;
    }
    else
    {
        strcpy(error_buff, "Unknown argument to --showfp. Expected: [=gui|stdout|none]");
    }
}

void
FRONT_PANEL_COMMAND_SWITCHES::ShowSwitch(char *buff)
{
    strcpy(buff, "--showfp[=gui|stdout|none]");
}
