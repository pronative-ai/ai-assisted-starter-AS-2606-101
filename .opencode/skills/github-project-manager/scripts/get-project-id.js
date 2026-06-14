const { execSync } = require("child_process");

function getProjectId(orgName, projectNumber) {
  const query = JSON.stringify({
    query: `query { organization(login: "${orgName}") { projectV2(number: ${projectNumber}) { id title } } }`,
  });
  const out = execSync(`gh api graphql --input -`, {
    input: query,
    encoding: "utf-8",
  });
  const parsed = JSON.parse(out);
  return parsed.data.organization.projectV2.id;
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error("Usage: node get-project-id.js <OrgName> <ProjectNumber>");
    process.exit(1);
  }
  console.log(getProjectId(args[0], parseInt(args[1], 10)));
}

module.exports = { getProjectId };
