//NOTE : You must create 20 sets of test data before running this script

/* Upsert almond custom setting */
almond__Almond_Settings__c setting = almond__Almond_Settings__c.getOrgDefaults();
if (setting == null){
    setting = new almond__Almond_Settings__c();
}
setting.almond__Header_Text_Color__c = '#FFFFFF';
setting.almond__Header_Background_Color__c = '#333333';
setting.almond__Company_Logo__c = 'https://googledrive.com/host/0B9dTGJKm2yPVWHMzSjhITVI5VEU';
upsert setting;

/* Delete track achievements */

List<almond__Achievement__c> x = [select id
                                          from almond__Achievement__c
                                          where Name LIKE 'Sample Track%'];
delete x;

/* Update training plan access */

List<almond__Training_Plan__c> tplans = [select id
                                                ,almond__Enable_Self_Registration__c
                                                ,almond__Self_Registration_Access__c
                                                from almond__Training_Plan__c];

for(almond__Training_Plan__c tp :tplans){
    tp.almond__Enable_Self_Registration__c = true;
    tp.almond__Self_Registration_Access__c = 'External';
}
update tplans;

/* Update achievement records */

List<almond__Achievement__c> achs = [select id
                                                 ,almond__Work_Badge_Giver__c
                                                 ,almond__Work_Badge_Message__c
                                                 ,almond__Work_Badge_Id__c
                                                 ,almond__Work_Badge_Image_URL__c
                                                 ,almond__Acquired_Image__c
                                                 ,almond__Eligible_Image__c
                                                from almond__Achievement__c];

List<WorkBadgeDefinition> badges = [select Id
                                        ,ImageUrl
                                        ,IsActive
                                        ,IsCompanyWide
                                        ,Name
                                        FROM WorkBadgeDefinition
                                        where IsActive = true
                                          limit :achs.size()];

for(Integer i = 0;i < badges.size(); i++){
    WorkBadgeDefinition bd = badges[i];
    almond__Achievement__c a = achs[i];
    a.almond__Acquired_Image__c = null;
    a.almond__Eligible_Image__c = null;
    a.almond__Work_Badge_Id__c = bd.Id;
    a.almond__Work_Badge_Message__c = 'Congratulations!';
    a.almond__Work_Badge_Image_URL__c = bd.ImageUrl;
    a.almond__Work_Badge_Giver__c = UserInfo.getUserId();
}

update achs;

/* Create a couple of learning categories */

List<almond__Learning_Category__c> lcs = new List<almond__Learning_Category__c>{
    new almond__Learning_Category__c(Name='Service', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVODJkQ1hWLW9xalk', almond__Text_Color__c = '#FFFFFF'),
    new almond__Learning_Category__c(Name='Sales', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVU0NqQ2w3SHRFT2s',almond__Text_Color__c = '#FFFFFF'),
    new almond__Learning_Category__c(Name='Marketing', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVSTdYX3JCRk5XT3M', almond__Text_Color__c = '#FFFFFF'),
    new almond__Learning_Category__c(Name='IT', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVdjlRYjlOY0Q5RDg',almond__Text_Color__c = '#FFFFFF'),
    new almond__Learning_Category__c(Name='Security', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVb20xeU5lcjZhc0k', almond__Text_Color__c = '#FFFFFF'),
    new almond__Learning_Category__c(Name='R&D', almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVMktYbHJkaXAzUjg', almond__Text_Color__c = '#FFFFFF')
};

insert lcs;

List<almond__Learning_Category__c> existinglcs = [select id from almond__Learning_Category__c];
//delete existinglcs;

Integer lcCount = 0;
List<almond__Training_Plan_Category__c> tpcsInsert = new List<almond__Training_Plan_Category__c>();
for(almond__Training_Plan__c tp : tplans){
    almond__Training_Plan_Category__c tpc = new almond__Training_Plan_Category__c();
    tpc.almond__Training_Plan__c = tp.Id;
    tpc.almond__Learning_Category__c = existinglcs[lcCount].id;
    tpcsInsert.add(tpc);
    if(Math.mod(tpcsInsert.size(),4)==0){
        lcCount++;
    }
}

insert tpcsInsert;

/* Create training track record */


Savepoint sp = Database.setSavepoint();
try{
    almond__Training_Track__c track = new almond__Training_Track__c();
    track.Name = 'Sample Track';
    track.almond__Status__c = 'Active';
    track.almond__Text_Color__c = '#FFFFFF';
    track.almond__Enable_all_external_accounts__c = true;
    track.almond__Description__c = 'Sample Description';
    track.almond__Background_Image_URL__c = 'https://googledrive.com/host/0B9dTGJKm2yPVbXhIZUpZVmFSTzQ';
    insert track;

    List<almond__Training_Track_Level__c> levels = new List<almond__Training_Track_Level__c>();
    for(Integer i = 1;i <=3;i++){
        almond__Training_Track_Level__c level = new almond__Training_Track_Level__c();
        level.Name = 'Level '+i+'';
        level.almond__Training_Track__c = track.Id;
        level.almond__Order__c  = i;
        level.almond__Description__c = 'Level '+i+' Description goes here...';
        levels.add(level);
    }
    insert levels;

    List<almond__Training_Track_Level_Item__c> levelItems = new List<almond__Training_Track_Level_Item__c>();
    Integer levelCount = 1;
    for(almond__Training_Track_Level__c level : levels){
        Integer topLimit = levelCount*3;
        Integer lowLevelCount = topLimit-2;
        for(Integer i = lowLevelCount;i <= topLimit; i++){
            almond__Training_Track_Level_Item__c item = new almond__Training_Track_Level_Item__c();
            item.almond__Training_Plan__c = tplans[i].Id;
            item.almond__Training_Track_Level__c = level.Id;
            levelItems.add(item);
        }
        levelCount++;
    }
    insert levelItems;
}catch(Exception e){
    System.debug(e.getMessage());
    Database.rollback(sp);
}
