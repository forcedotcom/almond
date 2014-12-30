Almond
===

Native Force.com Learning Management Application

Almond is a Learning Management app for the Salesforce1 platform. It allows users to create training content and training plans and assign these plans to users. Achievements can be given to users based on their training progress.

---

#### How to deploy the application :

1. Make sure [ant is installed](http://ant.apache.org/manual/install.html) in your local box
2. Make sure [node is installed](http://nodejs.org/)
3. Navigate to the build folder and instal the build dependencies:

   `npm install`

4. Make sure Work.com Thanks feature is enabled in your org
5. Make sure Translation Workbench is enabled in your org
6. Open your terminal or command prompt
7. Get the latest code for the app by using the following command :

   `git clone https://github.com/forcedotcom/almond.git`

8. Go into the almond directory
9. Update your credentials by making a copy of the sample-sfdc-build.properties file and rename it to "sfdc-build.properties".
10. Update the sfdc-build.properties with your credentials and login endpoint.
11. Navigate to the build folder using the terminal or command prompt
12. Run the deploy target by using the following command : `ant deploy -DrunAllTests=false -DcheckOnly=false`


### Package configuration:

You can find the latest configuration and user guides in the [appexchange listing](https://appexchange.salesforce.com/listingDetail?listingId=a0N3000000B5V2gEAF).

---
