Almond
===

Native Force.com Learning Management Application

Almond is a Learning Management app for the Salesforce1 platform. It allows users to create training content and training plans and assign these plans to users. Achievements can be given to users based on their training progress.

---
#### Deployment Prerequisites

1. Make sure Work.com Thanks feature is enabled in your org
2. Make sure Translation Workbench is enabled in your org


#### Deploy using the un-managed package (one-time only)

Go to the [appexchange listing](https://appexchange.salesforce.com/listingDetail?listingId=a0N3000000B5V2gEAF), click the "Get It Now" button and follow the instructions.

NOTE: This can only be done once, for updating the package you must deploy again using one of the methods below.

#### Deploy using the Deploy to Salesforce Button

<a href="https://githubsfdeploy.herokuapp.com?owner=forcedotcom&repo=almond" target="_blank">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

IMPORTANT: Deploying over an existing Almond installation will override any customizations you've done to the package code/components.

#### Deploy using ANT

1. Make sure [ant](http://ant.apache.org/manual/install.html) and [node.js](http://nodejs.org/) are installed in your local box
2. Navigate to the build folder and install the build dependencies using node package manager:

   `npm install`

3. Open your terminal or command prompt
4. Get the latest code for the app by using the following command :

   `git clone https://github.com/forcedotcom/almond.git`

5. Go into the almond directory
6. Update your credentials by making a copy of the sample-sfdc-build.properties file and rename it to "sfdc-build.properties".
7. Update the sfdc-build.properties with your credentials and login endpoint.
8. Navigate to the build folder using the terminal or command prompt
9. Run the deploy target by using the following command : `ant deploy -DrunAllTests=false -DcheckOnly=false`

IMPORTANT: Deploying over an existing Almond installation will override any customizations you've done to the package code/components.

### Configuration & User Guides

You can find the latest configuration and user guides in the [appexchange listing](https://appexchange.salesforce.com/listingDetail?listingId=a0N3000000B5V2gEAF).

---
