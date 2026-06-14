const { execSync } = require("child_process");

function addIssueToProject({ owner, repo, issueNumber, projectId = "", orgName = "", projectNumber = 0 }) {
  if (!projectId && orgName && projectNumber) {
    const query = JSON.stringify({
      query: `query { organization(login: "${orgName}") { projectV2(number: ${projectNumber}) { id } } }`,
    });
    const out = execSync(`gh api graphql --input -`, { input: query, encoding: "utf-8" });
    const parsed = JSON.parse(out);
    projectId = parsed.data.organization.projectV2.id;
  }

  if (!projectId) {
    throw new Error("Provide either projectId or both orgName and projectNumber");
  }

  const issueQuery = JSON.stringify({
    query: `query { repository(owner: "${owner}", name: "${repo}") { issue(number: ${issueNumber}) { id } } }`,
  });
  const issueOut = execSync(`gh api graphql --input -`, { input: issueQuery, encoding: "utf-8" });
  const issueParsed = JSON.parse(issueOut);
  const nodeId = issueParsed.data.repository.issue.id;

  const mutation = JSON.stringify({
    query: `mutation { addProjectV2ItemById(input: { projectId: "${projectId}" contentId: "${nodeId}" }) { item { id } } }`,
  });
  execSync(`gh api graphql --input -`, { input: mutation, encoding: "utf-8" });
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const params = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, "");
    let val = args[i + 1];
    if (key === "IssueNumber" || key === "ProjectNumber") {
      val = parseInt(val, 10);
    }
    params[key] = val;
  }
  addIssueToProject(params);
}

module.exports = { addIssueToProject };
