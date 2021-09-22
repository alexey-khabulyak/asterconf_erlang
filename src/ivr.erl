-module(ivr).
-behaviour(gen_statem).

-export([start/0, ivr_start/1, init/1, welcome/3, welcome_digits/3, callback_mode/0]).

-define(FS_NODE, 'freeswitch@freeswitch').
 
send_msg(UUID, App, Args) ->
    Headers = [{"call-command", "execute"},
        {"execute-app-name", atom_to_list(App)}, {"execute-app-arg", Args}],
    {sendmsg, ?FS_NODE} ! {sendmsg, UUID, Headers}.

name() -> ivr_statem.

start() -> gen_statem:start({local,name()}, ?MODULE, [], []).

ivr_start(Ref) ->
    io:format("Ref: ~p~n", [Ref]),
    {ok, NewPid} = ?MODULE:start(),
    {Ref, NewPid}.

init(State) -> 
    io:format("icall_fsm init ~p, PID: ~p~n", [State, self()]),
    {ok, welcome, []}.

callback_mode() -> state_functions.

welcome(EventType, {_FsEvent, {_Type , [UUID,EventTuple|CallData]}}, Data) ->
    io:format("WELCOME!! EventType: ~p~n CallData: ~p~n", [EventType, CallData]),
    {"Event-Name", EventName} = EventTuple,
    case EventName of
        "CHANNEL_PARK" -> 
            send_msg(UUID, playback, "voicemail/vm-greeting.wav"),
            {keep_state, Data};
        "PLAYBACK_STOP" ->
            send_msg(UUID, play_and_get_digits, "1 1 3 5000 # ivr/ivr-enter_ext.wav ivr/ivr-that_was_an_invalid_entry.wav menu_number [1-5]"),
            {next_state, welcome_digits, Data};
        _ -> 
            io:format("invalid event"),
            {keep_state, Data}
    end;

welcome(info, ok, Data) -> {keep_state, Data}.

welcome_digits(EventType, {_FsEvent, {_Type , [UUID,EventTuple|CallData]}}, Data) ->
    io:format("EventType: ~p~n UUID: ~p~n Event ~p~n, CallData ~p~n", [EventType, UUID, EventTuple, CallData]),
    {"Event-Name", EventName} = EventTuple,
    Application = lists:keyfind("Application", 1, CallData),
    PlaybackFile = lists:keyfind("soundfile", 1, CallData),
    case EventName of
        "CHANNEL_EXECUTE_COMPLETE"  when Application == {"Application", "play_and_get_digits"}->
            {"variable_menu_number", MenuNumber} = lists:keyfind("variable_menu_number", 1, CallData),
            send_msg(UUID, playback, "{soundfile=first}ivr/ivr-you_entered.wav"),
            {keep_state, MenuNumber};
        "PLAYBACK_STOP" when PlaybackFile == {"soundfile", "first"} ->
            send_msg(UUID, playback, "{soundfile=second}digits/" ++ Data ++ ".wav"),
            {keep_state, Data};
        "PLAYBACK_STOP" when PlaybackFile == {"soundfile", "second"} ->
            send_msg(UUID, hangup, ""),
            {stop, ok};
        _ -> {keep_state, Data}
    end;

welcome_digits(info, ok, Data) -> {keep_state, Data}.