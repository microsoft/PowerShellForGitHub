# PowerShellForGitHub PowerShell Module
## Contributing

Looking to help out?  You've come to the right place.  We'd love your help in making this the best
way to automate GitHub repos.

Looking for information on how to use this module?  Head on over to [README.md](README.md).

----------
#### Table of Contents

*   [Overview](#overview)
*   [Maintainers](#maintainers)
*   [Feedback](#feedback)
    *   [Bugs](#bugs)
    *   [Suggestions](#suggestions)
    *   [Questions](#questions)
*   [Static Analysis](#static-analysis)
*   [Module Manifest](#module-manifest)
*   [Logging](#logging)
*   [PowerShell Version](#powershell-version)
*   [Coding Guidelines](#coding-guidelines)
*   [Adding New Configuration Properties](#adding-new-configuration-properties)
*   [Code Comments](#code-comments)
*   [Debugging Tips](#debugging-tips)
*   [Pipeline Support](#pipeline-support)
*   [Formatters](#formatters)
*   [Testing](#testing)
    *   [Installing Pester](#installing-pester)
    *   [Configuring Your Environment](#configuring-your-environment)
    *   [Running the Tests](#running-the-tests)
    *   [Automated Tests](#automated-tests)
    *   [New Test Guidelines](#new-test-guidelines)
*   [Releasing](#releasing)
    *   [Updating the Version Number](#updating-the-version-number)
        *   [Semantic Versioning](#semantic-versioning)
    *   [Updating the CHANGELOG](#updating-the-changelog)
    *   [Adding a New Tag](#adding-a-new-tag)
    *   [Running the Release Build](#running-the-release-build)
    *   [Updating the Wiki documentation](#updating-the-wiki-documentation)
*   [Contributors](#contributors)
*   [Legal and Licensing](#legal-and-licensing)

----------

## Overview

We're excited that _you're_ excited about this project, and would welcome your contributions to help
it grow.  There are many different ways that you can contribute:

 1. Submit a [bug report](#bugs).
 2. Verify existing fixes for bugs.
 3. Submit your own fixes for a bug. Before submitting, please make sure you have:
   * Performed code reviews of your own
   * Updated the [test cases](#testing) if needed
   * Run the [test cases](#testing) to ensure no feature breaks or test breaks
   * Added the [test cases](#testing) for new code
   * Ensured that the code is free of [static analysis](#static-analysis) issues
 4. Submit a feature request.
 5. Help answer [questions](https://github.com/PowerShell/PowerShellForGitHub/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20label%3Aquestion).
 6. Write new [test cases](#testing).
 7. Tell others about the project.
 8. Tell the developers how much you appreciate the product!

You might also read these two blog posts about contributing code:
 * [Open Source Contribution Etiquette](http://tirania.org/blog/archive/2010/Dec-31.html) by Miguel de Icaza
 * [Don't "Push" Your Pull Requests](http://www.igvita.com/2011/12/19/dont-push-your-pull-requests/) by Ilya Grigorik.

Before submitting a feature or substantial code contribution, please discuss it with the
PowerShellForGitHub team via [Issues](https://github.com/PowerShell/PowerShellForGitHub/issues), and ensure it
follows the product roadmap. Note that all code submissions will be rigorously reviewed by the
PowerShellForGitHub Team. Only those that meet a high bar for both quality and roadmap fit will be merged
into the source.

## Maintainers

PowerShellForGitHub is maintained by:

- **[@HowardWolosky](http://github.com/HowardWolosky)**

As this module is a production dependency for Microsoft, we have a couple workflow restrictions:

- Anyone with commit rights can merge Pull Requests provided that there is a :+1: from one of
  the members above.
- Releases are performed by a member above so that we can ensure Microsoft internal processes
  remain up to date with the latest and that there are no regressions.

## Feedback

All issue types are tracked on the project's [Issues]( https://github.com/PowerShell/PowerShellForGitHub/issues)
page.

In all cases, make sure to search the list of issues before opening a new one.
Duplicate issues will be closed.

### Bugs

For a great primer on how to submit a great bug report, we recommend that you read:
[Painless Bug Tracking](http://www.joelonsoftware.com/articles/fog0000000029.html).

To report a bug, please include as much information as possible, namely:

* The version of the module (located in `PowerShellForGitHub.psd1`)
* Your OS version
* Your version of PowerShell (`$PSVersionTable.PSVersion`)
* As much information as possible to reproduce the problem.
* If possible, logs from your execution of the task that exhibit the erroneous behavior
* The behavior you expect to see

Please also mark your issue with the 'bug' label.

### Suggestions

We welcome your suggestions for enhancements to the extension.
To ensure that we can integrate your suggestions effectively, try to be as detailed as possible
and include:

* What you want to achieve / what is the problem that you want to address.
* What is your approach for solving the problem.
* If applicable, a user scenario of the feature / enhancement in action.

Please also mark your issue with the 'suggestion' label.

### Questions

If you've read through all of the documentation, checked the Wiki, and the PowerShell help for
the command you're using still isn't enough, then please open an issue with the `question`
label and include:

* What you want to achieve / what is the problem that you want to address.
* What have you tried so far.

----------

## Static Analysis

This project leverages the [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer/)
PowerShell module for static analysis.

It is expected that this module shall remain "clean" from the perspective of that module.

If you have never installed PSScriptAnalyzer, do this from an Administrator PowerShell console window:

```powershell
Install-Module -Name PSScriptAnalyzer
```

In the future, before running it, make sure it's up-to-date (run this from an Administrator
PowerShell console window):

```powershell
Update-Module -Name PSScriptAnalyzer
```

Once it's installed (or updated), from the root of your enlistment simply call

```powershell
Invoke-ScriptAnalyzer -Settings ./PSScriptAnalyzerSettings.psd1 -Path ./ -Recurse
```

That should return with no output.  If you see any output when calling that command,
either fix the issues that it calls out, or add a `[Diagnostics.CodeAnalysis.SuppressMessageAttribute()]`
with a justification explaining why it's ok to suppress that rule within that part of the script.
Refer to the [PSScriptAnalyzer documentation](https://github.com/PowerShell/PSScriptAnalyzer/) for
more information on how to use that attribute, or look at other existing examples within this module.

----------

### Module Manifest

This is a manifested PowerShell module, and the manifest can be found here:

    PowerShellForGitHub.psd1

If you add any new modules/files to this module, be sure to update the manifest as well.
New modules should be added to `NestedModules`, and any new functions or aliases that
should be exported need to be added to the corresponding `FunctionsToExport` or
`AliasesToExport` section.  Please keep all entries to those sections in **alphabetical order**.

----------

### Logging

Instead of using the built-in `Write-*` methods (`Write-Host`, `Write-Warning`, etc...),
please use

```powershell
Write-Log
```

which is implemented in Helpers.ps1.  It will take care of formatting your content in a
consistent manner, as well ensure that the content is logged to a file (if configured to do so
by the user).

----------

### PowerShell Version

This module must be able to run on PowerShell version 4.  It is permitted to add functionality
that requires a higher version of PowerShell, but only if there is a fallback implementation
that accomplishes the same thing in a PowerShell version 4 compatible way, and the path choice
is controlled by a PowerShell version check.

For an example of this, see `Write-Log` in `Helpers.ps1` which uses `Write-Information`
for `Informational` messages on v5+ and falls back to `Write-Host` for earlier versions:

```powershell
if ($PSVersionTable.PSVersion.Major -ge 5)
{
    Write-Information $ConsoleMessage -InformationAction Continue
}
else
{
    Write-Host $ConsoleMessage
}
```

----------

### Coding Guidelines

As a general rule, our coding convention is to follow the style of the surrounding code.
Avoid reformatting any code when submitting a PR as it obscures the functional changes of your change.

A basic rule of formatting is to use "Visual Studio defaults".
Here are some general guidelines

* No tabs, indent 4 spaces.
* Braces usually go on their own line,
  with the exception of single line statements that are properly indented.
* Use `camelCase` for instance fields, `PascalCase` for function and parameter names
* Avoid the creation of `script` scoped variables unless absolutely necessary.
  If referencing one, be sure to explicitly reference it by scope.
* Don't use globals.  If you want to add module configuration, [add a new property instead](#adding-new-configuration-properties).
* Avoid more than one blank empty line.
* Always use a blank line following a closing bracket `}` unless the next line itself is a closing bracket.
* Add full [Comment Based Help](https://technet.microsoft.com/en-us/library/hh847834.aspx) for all
  methods added, whether internal-only or external.  The act of writing this documentation may help
  you better design your function.
* File encoding should be ASCII (preferred) or UTF8 (with BOM) if absolutely necessary.
* We try to adhere to the [PoshCode Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle/tree/master/Best%20Practices)
  and [DSCResources Style Guidelines](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md)
  and think that you should too.
* We try to limit lines to 100 characters to limit the amount of horizontal scrolling needed when
  reviewing/maintaining code.  There are of course exceptions, but this is generally an enforced
  preference.  The [Visual Studio Productivity Power Tools](https://visualstudiogallery.msdn.microsoft.com/34ebc6a2-2777-421d-8914-e29c1dfa7f5d)
  extension has a "Column Guides" feature that makes it easy to add a Guideline in column 100
  to make it really obvious when coding.  If you use VS Code, this module's `.vscode/settings.json`
  configures that for you automatically.

----------

## Adding New Configuration Properties

If you want to add a new configuration value to the module, you must modify the following:
 * In `Import-GitHubConfiguration`, update `$config` to declare the new property along with
   its default value, being sure that PowerShell will understand what its type is. Properties
   should be alphabetical.
 * Update `Get-GitHubConfiguration` and add the new property name to the `ValidateSet` list
   so that tab-completion and documentation gets auto-updated. You shouldn't have to add anything
   to the body of the method. Property names should be alphabetical.
 * Add a new explicit parameter to `Set-GitHubConfiguration` to receive the property, along with
   updating the CBH (Comment Based Help) by adding a new `.PARAMETER` entry. You shouldn't
   have to add anything to the body of the method. Parameters should be alphabetical save for the
   `SessionOnly` switch, which should be last.

----------

### Code comments

It's strongly encouraged to add comments when you are making changes to the code and tests,
especially when the changes are not trivial or may raise confusion.
Make sure the added comments are accurate and easy to understand.
Good code comments should improve readability of the code, and make it much more maintainable.

That being said, some of the best code you can write is self-commenting.  By refactoring your code
into small, well-named functions that concisely describe their purpose, it's possible to write
code that reads clearly while requiring minimal comments to understand what it's doing.

----------

### Debugging Tips

You may find it useful to configure the module to log the body of all REST requests during
development of a new feature, to make it easier to see exactly what is being sent to GitHub.

```powershell
Set-GitHubConfiguration -LogRequestBody
```

----------

### Pipeline Support

This module has comprehensive support for the PowerShell pipeline.  It is imperative that all
new functionality added to the module embraces this design.

 * Most functions are declared as a `filter`.  This is the equivalent of a `function` where the
   body of the function is the `process` block, and the `begin/end` blocks are empty.

 * In limited cases where one of the inputs is an array of something, and you specifically want that
   to be processed as a single command (like adding a bunch of labels to a single issue at once),
   you can implement it as a `function` where you use `begin/process` to gather all of the values
   into a single internal array, and then do the actual command execution in the `end` block.  A
   good example of that which you can follow can be seen with `Add-GitHubIssueLabel`.

 * Any function that requires the repo's `Uri` to be provided should be additionally aliased with
   `[Alias('RepositoryUrl')]` and its `[Parameter()]` definition should include `ValueFromPipelineByPropertyName`.

 * Do not use any generic term like `Name` in your parameters.  That will end up causing unintended
   pipeline issues down the line.  For instance, if it's a label, call it `Label`, even though `Name`
   would make sense, other objects in the pipeline (like a `GitHub.Respository` object) also have
   a `name` property that would conflict.

 * You should plan on adding additional properties to all objects being returned from an API call.
   Any object that is specific to a repository should have a `RepositoryUrl` `NoteProperty` added
   to it, enabling it to be piped-in to any other command that requires knowing which repository
   you're talking about.  Additionally, any other property that might be necessary to uniquely
   identify that object in a different command should get added properties.  For example, with Issues,
   we add both an `IssueNumber` property and an `IssueId` property to it, as the Issue commands
   need to interact with the `IssueNumber` while the Event commands interact with the `IssueId`.
   We prefer to _only_ add additional properties that are believed to be needed as input to other
   commands (as opposed to creating alias properties for all of the object's properties).

 * For every major file, you will find an `Add-GitHub*AdditionalProperties` filter method at the end.
   If you're writing a new file, you'll need to create this yourself (and model it after an existing
   one).  The goal of this is that you can simply pipe the output of your `Invoke-GHRestMethod`
   directly into this method to update the result with the additional properties, and then return
   that modified version to the user.  The benefit of this approach is that you can then apply that
   filter on child objects within the primary object.  For instance, a `GitHub.Issue` has multiple
   `GitHub.User` objects, `GitHub.Label` objects, a `GitHub.Milestone` object and more.  Within
   `Add-GitHubIssueAdditionalProperties`, it just needs to know to call the appropriate
   `Add-GitHub*AdditionalProperties` method on the qualifying child properties, without needing to
   know anything more about them.

 * That method will also "type" information to each object.  This is forward-looking work to ease
   support for providing formatting of various object types in the future.  That type should be
   defined at the top of the current file at the script level (see other files for an example),
   and you should be sure to both specify it in the `.OUTPUTS` section of the Comment Based Help (CBH)
   for the command, as well as with `[OutputType({$script:GitHubUserTypeName})]` (for example).

 * Going along with the `.OUTPUTS` is the `.INPUTS` section.  Please maintain this section as well.
   If you add any new type that will gain a `RepositoryUrl` property, then you'll need to update
   virtually _all_ of the `.INPUTS` entries across all of the files where the function has a `Uri`
   parameter.  Please keep these type names alphabetical.

 * To enable debugging issues involving pipeline support, there is an additional configuration
   property that you might use:  `Set-GitHubConfiguration -DisablePipelineSupport`.  That will
   prevent the module from adding _any_ additional properties to the objects.

----------

### Formatters

[Our goal](https://github.com/microsoft/PowerShellForGitHub/issues/27) is to have automattic
formatting for all `GitHub.*` types that this project defines.

Formatting was first introduced to the project with [#205](https://github.com/microsoft/PowerShellForGitHub/pull/205),
and succcesive PR's which introduce new types have added their additional formatters as well.
Eventually we will get Formatters for all previously introduced types as well.

Formatter files can be found in [/Formatters](https://github.com/microsoft/PowerShellForGitHub/tree/master/Formatters).

When adding a new formatter file, keep the following in mind:

* One formatter file per PowerShell module file, and name them similarly
  (e.g. `GitHubRepositories.ps1` gets a `Formatters\GitHubRepositories.Format.ps1xml` file)
* Be sure to add the formatter file to the manifest (common mistake to forget this).
* Don't display all the type's properties ...just choose the most relevant pieces of information;
  sometimes this might mean using a script block to grab an inner-property or to perform a
  calculation.

----------

### Testing
[![Build status](https://dev.azure.com/ms/PowerShellForGitHub/_apis/build/status/PowerShellForGitHub-CI?branchName=master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/ms/PowerShellForGitHub/109/master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)
[![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/ms/PowerShellForGitHub/109/master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)


#### Installing Pester
This module supports testing using the [Pester UT framework](https://github.com/pester/Pester).

To install it:

```powershell
Install-Module -Name Pester -MinimumVersion 5.3.3 -AllowClobber -SkipPublisherCheck -Force
```

#### Configuring Your Environment
The tests intentionally do not mock out interaction with the real GitHub API, as we want to know
when our interaction with the API has been broken.  That means that to execute the tests, you will
need Administrator privilege for an account.  For our purposes, we have a "test" account that our
team uses for having the tests [run automated](#automated-tests).  For you to run the tests locally,
you must make a couple changes:

 1. Choose if you'll be executing the tests on your own personal account or your own test account
    (the tests should be non-destructive, but ... hey ... we are developing code here, mistakes happen.)
 2. Update your local copy of [tests/config/Settings.ps1](./tests/config/Settings.ps1) to note
    the `OwnerName` and `OrganizationName` that the tests will be running under.
    > While you can certainly check-in this file to your own fork, please DO NOT include your
    > changes as part of any pull request that you may make.  The `.gitignore` file tries
    > to help prevent that.
 3. Run `Set-GitHubAuthentication` to ensure that it is configured with an administrator-level
    Access Token for the specified owner/organization.
    > Unfortunately, you cannot use `-SessionOnly` with `Set-GitHubAuthentication` when testing,
    > as Pester works by making new sessions for every test.  That means that it must be "globally"
    > configured with that access token for the duration of the Pester test execution.

#### Running the Tests
Tests can be run either from the project root directory or from the `Tests` subfolder.
Navigate to the correct folder and simply run:

```powershell
Invoke-Pester
```

Make sure you have previously configured your Access Token via `Set-GitHubAuthentication`.
Please keep in mind some tests may fail on your machine, as they test private items (e.g. secret teams) which your key won't have access to.

Pester can also be used to test code-coverage, like so:

```powershell
$pesterConfig = New-PesterConfiguration
$pesterConfig.CodeCoverage.Path = @("$root\GitHubLabels.ps1")
$pesterConfig.CodeCoverage.Enabled = $true

Invoke-Pester -Configuration $pesterConfig
# Be sure you're not passing this in to -PesterOption, since that's different than the configuration.
```

This command tells Pester to check the `GitHubLabels.ps1` file for code-coverage.

The code-coverage object can be captured and interacted with, like so:

```powershell
$pesterConfig = New-PesterConfiguration
$pesterConfig.CodeCoverage.Path = @("$root\GitHubLabels.ps1")
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.Run.PassThru = $true

$cc = (Invoke-Pester -Configuration $pesterConfig).CodeCoverage
```

There are many more nuances to code-coverage, see
[its documentation](https://pester.dev/docs/usage/code-coverage) for more details.

#### Automated Tests
[![Build status](https://dev.azure.com/ms/PowerShellForGitHub/_apis/build/status/PowerShellForGitHub-CI?branchName=master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/ms/PowerShellForGitHub/109/master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)
[![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/ms/PowerShellForGitHub/109/master)](https://dev.azure.com/ms/PowerShellForGitHub/_build/latest?definitionId=109&branchName=master)

These test are configured to automatically execute upon any update to the `master` branch
of `microsoft/PowerShellForGitHub`.

The [Azure DevOps pipeline](https://dev.azure.com/ms/PowerShellForGitHub/_build?definitionId=109&_a=summary)
has been [configured](https://github.com/microsoft/PowerShellForGitHub/blob/master/build/pipelines/templates/run-unitTests.yaml#L25-L28)
to execute the tests against a test GitHub account (for the user `PowerShellForGitHubTeam`,
and the org `PowerShellForGitHubTeamTestOrg`).  You will see the AccessToken being referenced there
as well...it is stored, encrypted, within Azure DevOps.  It is not accessible for use outside of
the CI pipeline.  To run the tests locally with your own account, see
[configuring-your-environment](#configuring-your-environment).

> Your change must successfully pass all tests before they will be merged.  While we will run a CI
> build on your behalf for any submitted pull request, it's to your benefit to verify your changes
> locally first.

#### New Test Guidelines
Your tests should have NO dependencies on an account being set up in a specific way.  They should
get the configured account set up in the appropriate state that it can then test/verify.  In this
way, anyone should be able to run the tests from their own machine/account.

Use a new GUID for any object that you have to create (repository, label, team name, etc...) to avoid
any possible name collisions with existing objects on the executing user's accounts.

----------

### Releasing

When new code changes are checked in to the repo, most users of the module will not see those changes
unless an updated module gets published by Microsoft to
[PowerShell Gallery](https://www.powershellgallery.com/packages/PowerShellForGitHub).

The general guidance on publishing an update is that changes should not be in `master` more than
one week without having been published through PowerShell Gallery as well.

When you are ready to publish a new update, the following steps are necessary:
  * Create (and complete) a changelist that:
    * Updates the [version number](#updating-the-version-number)
    * Updates the [CHANGELOG.md](./CHANGELOG.md) (and [contributors](#contributors) list if necessary)
  * [Add a tag](#adding-a-new-tag) for the new version to the repo
  * [Queue a new release build](#running-the-release-build)

#### Updating the Version Number

Whenever new changes to the module are to be released to PowerShellGallery, it is important to
properly update the version of the module.  The version number is stored in the module manifest
([PowerShellForGitHub.psd1](https://github.com/microsoft/PowerShellForGitHub/blob/master/PowerShellForGitHub.psd1)),
and it should be updated following the [Semantic Versioning](#semantic-versioning) standard.

> The update to the module manifest should happen in the same changelist where the
> [CHANGELOG is updated](#updating-the-changelog).

##### Semantic Versioning

This project follows [semantic versioning](http://semver.org/) in the following way:

    <major>.<minor>.<patch>

Where:
* `<major>` - Changes only with _significant_ updates.
* `<minor>` - If this is a feature update, increment by one and be sure to reset `<patch>` to 0.
* `<patch>` - If this is a bug fix, leave `<minor>` alone and increment this by one.

#### Updating the CHANGELOG
To update [CHANGELOG.md](./CHANGELOG.md), just duplicate the previous section and update it to be
relevant for the new release.  Be sure to update all of the sections:
  * The version number
  * The hard path to the change (we'll get that path working [in a moment](#adding-a-new-tag))
  * The release date
  * A brief list of all the changes (use a `-` for the bullet point if it's fixing a bug, or a `+` for a feature)
  * The link to the pull request (pr) (so that the discussion on the change can be easily reviewed) and the changelist (cl)
  * The author (and a link to their profile)
  * If it's a new contributor, also add them to the [Contributors](#contributors) list below.

Then get a new pull request out for that change and for the change to the
[module manifest's version number](#updating-the-version-number).

#### Adding a New Tag
To add a new tag:
   1. Make sure that you're in a clone of the actual repo and not your own private fork.
   2. Make sure that you've already merged in the change that updates the module version.
   3. Make sure that you have checked out `master` and that it's fully up-to-date
   4. Run `git tag -a '<version number>'`
   5. In the pop-up editor, just copy the content from the CHANGELOG that you just wrote, but remove
      any of the `###` heading blocks since those will be dropped from git as comments instead of
      headings.
   6. Save and close the editor
   7. Run `git push --tags` to upload the new tag you just created

If you want to make sure you get these tags on any other forks/clients, you can run
`git fetch origin --tags` or `git fetch upstream --tags`, or whatever you've named the source to be.

> Doing this makes it possible for users to simply run `git checkout <version number>` to quickly
> set their clone to the state of any previous version.
> It also has the added benefit that GitHub will automatically create a new "Release" in the
> Releases tab of the project for this new version.

#### Running the Release Build

A [YAML definition exists](https://github.com/microsoft/PowerShellForGitHub/blob/master/build/pipelines/azire-pipelines.release.yaml)
that will run the equivalent of the CI build, followed by the necessary steps to sign the module
files and publish the update to PowerShell Gallery.  This YAML file can only be run by a Microsoft
maintainer because it accesses internal services to sign the module files with Microsoft's certificate.

> **Microsoft Maintainers**: You can access the internal pipeline which can execute the release build
> [here](https://microsoft.visualstudio.com/Apps/_build?definitionId=43898).  Simply hit `Queue` to
> get a new module released.
>
> Instructions for updating the `PowerShellGalleryApiKey` secret in the pipeline can be found in the
> [internal Microsoft repo for this project](https://microsoft.visualstudio.com/Apps/_git/eng.powershellforgithub).

#### Updating the Wiki Documentation

The [Wiki](https://github.com/microsoft/PowerShellForGitHub/wiki) contains the full documentation
for all exported commands from the module, thanks to [platyPS](https://github.com/PowerShell/platyPS).

Every time a new release occurs, the Wiki should be updated to reflect any changes that occurred
within the module.

1. Ensure that you have cloned the Wiki:

   ```
   git clone https://github.com/microsoft/PowerShellForGitHub.wiki.git
   ```

2. Open a PowerShell 7+ console window (don't use Windows PowerShell as there's a platyPS bug
   with that version regarding multi-line examples) and navigate to your Wiki clone.

3. Run this command (assuming that you have a `PowerShellForGitHub` clone at the same level as your
   Wiki clone):

   ```powershell
   ..\PowerShellForGitHub\build\scripts\Build-Wiki.ps1 -Path .\ -RemoveDeprecated -Verbose -Force
   ```

4. Verify the changes all make sense.  You will also need to manually copy the core content of
   `PowerShellForGitHub.md` into `Home.md`.  For the time being, we are duplicating that content
   in Home until such time as we have better content to put there.

5. Commit the change and directly push it to the Wiki's `master` branch...no need to go through
   a pull request for the Wiki changes.

> This is not currently automated as part of the [Release pipeline](#running-the-release-build)
> because I don't currently want to store any credentials/tokens with write access to the repo
> in the pipeline.

----------

### Contributors

Thank you to all of our contributors, no matter how big or small the contribution:

- **[Howard Wolosky (@HowardWolosky)](http://github.com/HowardWolosky)**
- **[Karol Kaczmarek (@KarolKaczmarek)](https://github.com/KarolKaczmarek)**
- **[Josh Rolstad (@jrolstad)](https://github.com/jrolstad)**
- **[Zachary Alexander (@zjalexander)](http://github.com/zjalexander)**
- **[Andrew Dahl (@aedahl)](http://github.com/aedahl)**
- **[Pepe Rivera (@joseartrivera)](https://github.com/joseartrivera)**
- **[Ethan Gottlieb (@etgottli)](https://github.com/etgottli)**
- **[Fran&ccedil;ois-Xavier Cat (@lazywinadmin)](https://github.com/lazywinadmin)**
- **[Cliff Chapman (@Cellivar)](https://github.com/Cellivar)**
- **[Robert Holt (@rjmholt)](https://github.com/rjmholt)**
- **[Steven Maglio (@smaglio81)](https://github.com/smaglio81)**
- **[Kiran Reddy (@v2kiran)](https://github.com/v2kiran)**
- **[Darío Hereñú (@kant)](https://github.com/kant)**
- **[@wikijm](https://github.com/wikijm)**
- **[Przemysław Kłys (@PrzemyslawKlys)](https://github.com/PrzemyslawKlys)**
- **[Matt Boren (@mtboren)](http://github.com/mtboren)**
- **[Shannon Deminick (@Shazwazza)](http://github.com/Shazwazza)**
- **[Jess Pomfret (@jpomfret)](https://github.com/jpomfret)**
- **[Giuseppe Campanelli (@themilanfan)](https://github.com/themilanfan)**
- **[Christoph Bergmeister (@bergmeister)](https://github.com/bergmeister)**
- **[Simon Heather (@X-Guardian)](https://github.com/X-Guardian)**
- **[Neil White (@variableresistor)](https://github.com/variableresistor)**
- **[Mark Curole(@tigerfansga)](https://github.com/tigerfansga)**
- **[Jason Vercellone(@vercellone)](https://github.com/vercellone)**
- **[Andy Jordan (@andyleejordan)](https://github.com/andyleejordan)**

----------

### Legal and Licensing

PowerShellForGitHub is licensed under the [MIT license](..\LICENSE).

You will need to complete a Contributor License Agreement (CLA) for any code submissions.
Briefly, this agreement testifies that you are granting us permission to use the submitted change
according to the terms of the project's license, and that the work being submitted is under
appropriate copyright. You only need to do this once.

When you submit a pull request, [@msftclas](https://github.com/msftclas) will automatically
determine whether you need to sign a CLA, comment on the PR and label it appropriately.
If you do need to sign a CLA, please visit https://cla.microsoft.com and follow the steps.
