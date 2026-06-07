import json

def extract_api_info(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    paths = data.get('paths', {})
    
    order_paths = [
        "/orders",
        "/orders/{id}/verify-payment",
        "/orders/{id}",
        "/orders/{id}/sub-orders",
        "/orders/reviews",
        "/orders/sub-orders/{id}/review"
    ]
    
    # find exact paths or paths containing order
    for path, methods in paths.items():
        if "/order" in path:
            print(f"Path: {path}")
            for method, details in methods.items():
                print(f"  Method: {method.upper()}")
                print(f"  Summary: {details.get('summary', '')}")
                tags = details.get('tags', [])
                if tags:
                    print(f"  Tags: {tags}")
                
                req_body = details.get('requestBody', {})
                if req_body:
                    print("  Request Body Example:")
                    try:
                        content = req_body.get('content', {}).get('application/json', {})
                        if 'example' in content:
                            print(f"    {content['example']}")
                        elif 'schema' in content:
                            print(f"    Schema: {content['schema']}")
                    except Exception as e:
                        pass
                
                responses = details.get('responses', {})
                if '200' in responses:
                    print("  Response (200) Example:")
                    try:
                        content = responses['200'].get('content', {}).get('application/json', {})
                        if 'example' in content:
                            print(f"    {content['example']}")
                    except Exception as e:
                        pass
            print("-" * 40)

if __name__ == '__main__':
    extract_api_info(r'c:\Hansuke\Work\raheeq_main\assets\hoppscotch-team-collections-openapi.json')
