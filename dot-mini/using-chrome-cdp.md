ok, code is opened with cdp port 9333, you can use chrome dev tool mcp 9333 to reach it

test it:
- with 9333
- with spawned code instance wihtout extensions enabled ( @docs/important/how-to-test.md )

and if you have to "sleep" to wait for sth
do use cli `date` to get start/stop time to see how long actually it took
also, use playwright to simulate your test after your manual tests to speed tests up