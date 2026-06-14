const { execSync } = require("child_process");

async function newGitHubIssue({ owner, repo, title, body, labels = [], projectId = "" }) {
  const token = execSync(`gh auth token`, { encoding: "utf-8" }).trim();
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  const payload = { title, body };
  if (labels.length > 0) payload.labels = labels;

  const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/issues`, {
    method: "POST",
    headers,
    body: JSON.stringify(payload),
  });
  const issue = await response.json();

  if (projectId && issue.node_id) {
    const mutation = JSON.stringify({
      query: `mutation { addProjectV2ItemById(input: { projectId: "${projectId}" contentId: "${issue.node_id}" }) { item { id } } }`,
    });
    try {
      execSync(`gh api graphql --input -`, { input: mutation, encoding: "utf-8" });
    } catch {
      // ignore project add failure
    }
  }

  return issue;
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const params = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, "");
    let val = args[i + 1];
    if (key === "Labels") {
      val = val.split(",").map((s) => s.trim());
    }
    params[key] = val;
  }
  newGitHubIssue(params).then((issue) => console.log(JSON.stringify(issue)));
}

module.exports = { newGitHubIssue };
