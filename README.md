Almond
===

Native Force.com Learning Management Application

Almond is a Learning Management app for the Salesforce1 platform. It allows users to create training content and training plans and assign these plans to users. Achievements can be given to users based on their training progress.

---

#### How to deploy the application :

1. Make sure [ant is installed](http://ant.apache.org/manual/install.html) in your local box
2. Open your terminal or command prompt
3. Get the latest code for the app by using the following command :

   `git clone https://github.com/forcedotcom/almond.git`

4. Go into the almond directory
5. Update your credentials by making a copy of the sample-sfdc-build.properties file and rename it to "sfdc-build.properties".
6. Update the sfdc-build.properties with your credentials and login endpoint.
7. Navigate to the build folder using the terminal or command prompt
8. Run the deploy target by using the following command : `ant deploy -DrunAllTests=false -DcheckOnly=false`


### Package configuration:

You can find the latest configuration and user guides in the [appexchange listing](https://appexchange.salesforce.com/listingDetail?listingId=a0N3000000B5V2gEAF).

---
