vim9script

command! -nargs=0 Tasks call PrintTasks()
command! -nargs=* Addtsk call AddTask(<f-args>)
command! -nargs=* Donetsk call SetDone(<f-args>)
command! -nargs=* Closetsk call SetClose(<f-args>)

const TASK_CSV = 'task.csv'
const TASK_HISTORY = 'task_history.csv'
const AUTO_NUM_MASTER = 'id_master.csv'

const TASK_STATUS_DONE = 'done'
const TASK_STATUS_CLOSE = 'close'

var thisPluginDir = expand('%:p:h')

# Print task from csv file
def PrintTasks(): void
    redraw!

    var tasks = ReadCsv(TASK_CSV)
    var dispTasks = FormatDispTasks(tasks)

    for tsk in dispTasks
        echon tsk .. "\n"
    endfor

enddef

def FormatDispTasks(tasklist: list<string>): list<string>
    var results = []

    var cnt = 1
    for task in tasklist
        var taskItems = task->split(',')
        var [id,status,startdate,duedate,completedate,closeddate,subject,isarchived; remark] = taskItems

        var dispCnt = string(cnt)

        if !!str2nr(isarchived)
            dispCnt = dispCnt .. 'a'
        endif

        results->add($'{RPad(dispCnt, " ", 7)} {id->GetDispId()} [{RPad(status, " ", 7)}] {startdate} - {duedate} {subject}')

        cnt += 1
    endfor

  return results

enddef

def GetDispId(taskId: string): string
    return taskId->LPad('0', 5)
enddef

def LPad(value: string, padstr: string, length: number): string
    var result = value

    while len(result) < length
        result = padstr .. result
    endwhile

    return result
enddef

def RPad(value: string, padstr: string, length: number): string
    var result = value

    while len(result) < length
        result = result .. padstr
    endwhile

    return result
enddef

def ReadCsv(fileName: string): list<string>
    var filePath = GetFilePath($'database/{fileName}')

    var results = []
    if filereadable(filePath)
        results = readfile(filePath)
    else
        echon $'file not found: {filePath}'
    endif

    return results

enddef

def GetFilePath(fileName: string): string
    return thisPluginDir .. '/' .. fileName
enddef

def AddTask(...taskconf: list<string>): void
    var [startdate, duedate, subject] = taskconf
    var [currentId] = ReadCsv(AUTO_NUM_MASTER)

    var id = str2nr(currentId) + 1
    var task = [
          string(id),
          'open',
          startdate,
          duedate,
          '',
          '',
          subject,
          '0',
          '',
        ]->join(',')

    writefile([task], GetFilePath($'database/{TASK_CSV}'), 'a')
    writefile([id], GetFilePath($'database/{AUTO_NUM_MASTER}'))

    redraw!
    echon $'Task created. #{string(id)}: {subject}'

enddef

def SetDone(...taskIdList: list<string>): void
    SetStatus(taskIdList, TASK_STATUS_DONE)
enddef

def SetClose(...taskIdList: list<string>): void
    SetStatus(taskIdList, TASK_STATUS_CLOSE)
enddef

def SetStatus(taskIdList: list<string>, status: string): void
    var tasks = GetTasks()

    for taskId in taskIdList
        if tasks->has_key(taskId)
            var tasksItems = tasks[taskId]
            tasksItems[1] = status
        endif
    endfor

    var csvRows = []
    for taskItems in values(tasks)->sort( (i1, i2) => str2nr(i1[0]) - str2nr(i2[0]) )
        csvRows->add( taskItems->join(',') )
    endfor

    writefile(csvRows, GetFilePath($'database/{TASK_CSV}'))

    redraw!
    echon $'Tasks {status}: #{taskIdList->join(", ")}'
enddef

def GetTasks(): dict<list<string>>
    var tasks = ReadCsv(TASK_CSV)

    var results = {}
    for task in tasks
        var taskItems = task->split(',')

        results[taskItems[0]] = taskItems
    endfor

    return results
enddef
