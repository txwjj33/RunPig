
function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
end

CCFileUtils:sharedFileUtils():addSearchPath("res/")
require("game")
game.startup()

--function get_dir_file(dirpath,func)
--    --os.execute("dir " .. dirpath .. " /s > temp.txt")
--    os.execute('dir "' .. dirpath .. '" /s > temp.txt')
--    io.input("temp.txt")
--    local dirname = ""
--    local filename = ""
--    for line in io.lines() do
--        local a,b,c
--        --ƥ��Ŀ¼
--        a,b,c=string.find(line,"^%s*(.+)%s+��Ŀ¼")
--        if a then
--         dirname = c
--         --print(c)
--     end
--     --ƥ���ļ�
--        a,b,c=string.find(line,"^%d%d%d%d%-%d%d%-%d%d%s-%d%d:%d%d%s-[%d%,]+%s+(.+)%s-$")
--        if a then
--         filename = c
--         --print(c)
--         func(dirname .. "\\" .. filename)
--        end
--     --print(line)
--    end
--end
----��ȡָ�������һ���ַ���λ��
--function get_last_word(all,word)
--    local b = 0
--    local last = nil
--    while true do
--        local s,e = string.find(all, word, b) -- find 'next' word
--        if s == nil then
--         break
--        else
--         last = s
--        end
--         b = s + string.len(word)
--    end
--    return last
--end

------����ͨ��get_last_word��ȡָ���ļ�����Ӧ·������Ӧ�ļ���
----filepath = "c:\\windows\\explorer.exe"
----pos=get_last_word(filepath,"\\")
----dirname=string.sub(filepath,1,pos)
----filename=string.sub(filepath,pos+1,-1)
----print(dirname,filename)
------ʹ��print������C:\Program Files\Internet Explorer�ļ������ļ����д���
------get_dir_file('"C:\\Program Files\\Internet Explorer"',print)
----get_dir_file('D:\\levels',print)