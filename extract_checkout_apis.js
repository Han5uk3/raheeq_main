const fs = require('fs');

const data = JSON.parse(fs.readFileSync('c:/Hansuke/Work/raheeq_main/assets/hoppscotch-team-collections-openapi.json', 'utf8'));
const paths = data.paths || {};

for (const [path, methods] of Object.entries(paths)) {
    if (path.includes('/checkout')) {
        console.log(`Path: ${path}`);
        for (const [method, details] of Object.entries(methods)) {
            console.log(`  Method: ${method.toUpperCase()}`);
            console.log(`  Summary: ${details.summary || ''}`);
            if (details.tags) {
                console.log(`  Tags: ${details.tags.join(', ')}`);
            }
            
            const reqBody = details.requestBody || {};
            if (reqBody.content && reqBody.content['application/json']) {
                console.log("  Request Body Example:");
                const content = reqBody.content['application/json'];
                if (content.example) {
                    console.log(`    ${typeof content.example === 'string' ? content.example : JSON.stringify(content.example, null, 2)}`);
                } else if (content.schema) {
                    console.log(`    Schema: ${JSON.stringify(content.schema, null, 2)}`);
                }
            }
            
            const responses = details.responses || {};
            if (responses['200'] && responses['200'].content && responses['200'].content['application/json']) {
                console.log("  Response (200) Example:");
                const content = responses['200'].content['application/json'];
                if (content.example) {
                    console.log(`    ${typeof content.example === 'string' ? content.example : JSON.stringify(content.example, null, 2)}`);
                }
            }
        }
        console.log("-".repeat(40));
    }
}
