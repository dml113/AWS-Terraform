# README.md

README.md 파일과 공존하는 Lambda 폴더안의 경로들은 수정되면 안 됩니다.
```
source.zip
├─node_modules
|   └─ ...
├─index.js
├─package.json
├─package-lock.json
```

- First !
 
Reference/03Seoul/01/source/index.js 를 편집 모드로 전향합니다.

5번째 줄의 const BUCKET 부분의 값을 생성된 Bucket Name으로 수정합니다.

저장후 source.zip으로 압축시켜, 경로를 그대로 유지한 채 lambda에 zip파일로 업로드 합니다.


- Second !
  
Add trigger -> CloudFront -> Deploy to Lambda@Edge -> Distribution=<ID> -> CacheBehavior=/images/* -> CloudFrontEvent=OriginResponse
