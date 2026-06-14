const { execSync } = require("child_process");

function cleanBodyText(body) {
  let clean = body;
  clean = clean.replace(/\r\n/g, "\n");
  clean = clean.replace(/\\n/g, "\n");
  clean = clean.replace(/\\n/g, "\n");
  clean = clean.replace(/\n{3,}/g, "\n\n");
  return clean.trim();
}

async function updateGitHubIssueBody({ owner, repo, number, body = "", append, clean }) {
  const token = execSync(`gh auth token`, { encoding: "utf-8" }).trim();
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  const issueResponse = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/issues/${number}`,
    { headers }
  );
  const issue = await issueResponse.json();
  const currentBody = issue.body || "";

  let payload;
  if (clean) {
    payload = { body: cleanBodyText(currentBody) };
  } else if (append) {
    payload = { body: `${currentBody}\n\n${body}` };
  } else {
    payload = { body };
  }

  const updateResponse = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/issues/${number}`,
    {
      method: "PATCH",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }
  );
  return await updateResponse.json();
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const params = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, "");
    let val = args[i + 1];
    if (key === "Append" || key === "Clean") {
      val = true;
    }
    params[key] = val;
  }
  updateGitHubIssueBody(params).then((result) => console.log(JSON.stringify(result)));
}

module.exports = { updateGitHubIssueBody, cleanBodyText };
