-module(xml_handler).
-export([start/0, init/0, loop/0]).

start() ->
    spawn(?MODULE, init, []).

init() ->
    {foo, 'freeswitch@freeswitch'} ! {bind, directory},
    {foo, 'freeswitch@freeswitch'} ! {bind, dialplan},
    loop().

loop() ->
    receive
        {fetch, directory, _Tag, _Key, Value, FetchID, Params}  -> 
            % io:format("~p~n", [Tag]),
            % io:format("~p~n", [Key]),
            % io:format("~p~n", [Value]),
            io:format("~p~n", [FetchID]),
            io:format("~p~n", [Params]),
            User = case lists:keytake("user", 1, Params) of
                {value, {"user", UserNumber}, _} -> UserNumber;
                _ -> 9999
            end,
            ReplyXML =
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
                <document type=\"freeswitch/xml\">
                  <section name=\"directory\" description=\"\">
                    <domain name=\"" ++ Value ++ "\">
                      <groups>
                        <group name=\"default\" description=\"\">
                          <users>
                            <user id=\"" ++ User ++ "\">
                              <params>
                                <param name=\"password\" value=\"strongpassword\"/>
                              </params>
                              <variables>
                                <variable name=\"asdf\" value=\"test\"/>
                              </variables>
                            </user>
                          </users>
                        </group>
                      </groups>
                    </domain>
                  </section>
                </document>",
            {foo, 'freeswitch@freeswitch'} ! {fetch_reply, FetchID, ReplyXML},
            loop();
        {fetch, dialplan, _Tag, _Key, _Value, FetchID, _Params} ->
            % io:format("~p~n", [Tag]),
            % io:format("~p~n", [Key]),
            % io:format("~p~n", [Value]),
            % io:format("~p~n", [FetchID]),
            % io:format("~p~n", [Params]),
            ReplyXML =
                "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
                <document type=\"freeswitch/xml\">
                  <section name=\"dialplan\" description=\"\">
                    <context name=\"public\">
                      <extension name=\"call\">
                        <condition>
                          <action application=\"info\" data=\"\"/>
                          <action application=\"erlang\" data=\"ivr:ivr_start neon@neon\"/>
                        </condition>
                      </extension>
                    </context>
                  </section>
                </document>",
            {foo, 'freeswitch@freeswitch'} ! {fetch_reply, FetchID, ReplyXML},
            loop()
    end.
