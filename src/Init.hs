module Init where

import Configuration
import TodoArguments

import System.Directory
import System.FilePath
import Database.HDBC
import Database.HDBC.Sqlite3

createDatabase :: TodoCommand -> Config -> IO ()
createDatabase initCommand config = do
   case databaseFile initCommand of
      Nothing -> if userLevel initCommand
                     then runCreateDatabase $ defaultDatabaseLocation config
                     else runCreateDatabase $ hiddenFileName config
      Just databasePath -> runCreateDatabase databasePath

runCreateDatabase :: String -> IO ()
runCreateDatabase filename = do
   conn <- connectSqlite3 filename
   runRaw conn tableUpdates 
   runRaw conn tableItems
   runRaw conn tableItemEvents
   runRaw conn tableTags
   runRaw conn tableTagMap
   commit conn
   disconnect conn
   
tableUpdates = "create table updates ( version integer primary key, description text, upgradeDate date );"

tableItems = "create table items ("
              ++ "id integer primary key autoincrement not null,"
              ++ "description text not null,"
              ++ "current_state integer not null default 0,"
              ++ "created_at datetime not null,"
              ++ "parent_id integer,"
              ++ "priority integer not null,"
              ++ "FOREIGN KEY(parent_id) references items(id) on delete cascade"
              ++ ");"

tableItemEvents = "create table item_events ("
                  ++ "id integer primary key autoincrement not null,"
                  ++ "item_id integer not null,"
                  ++ "item_event_type integer not null,"
                  ++ "event_description text,"
                  ++ "occurred_at datetime not null,"
                  ++ "FOREIGN KEY(item_id) references items(id) on delete cascade"
                  ++ ");"

tableTags = "create table tags ("
            ++ "id integer primary key autoincrement not null,"
            ++ "tag_name text not null,"
            ++ "created_at datetime not null"
            ++ ");"

tableTagMap = "create table tag_map ("
            ++ "item_id integer not null,"
            ++ "tag_id integer not null,"
            ++ "created_at datetime not null,"
            ++ "FOREIGN KEY(item_id) references items(id) on delete cascade,"
            ++ "FOREIGN KEY(tag_id) references tags(id) on delete cascade"
            ++ ");"

