"""
main.py

Entry point for the MCQ Grader backend API.

Features:
- FastAPI application setup.
- Includes routers for user and test management.
- Endpoints for processing MCQ answer sheets and mark schemes.
- Handles file uploads and image processing using YOLO-based detection.
- Integrates with MongoDB for data storage.

Key Endpoints:
- GET /: Health check endpoint.
- POST /process_direct: Upload and process an answer sheet image.
- Routers:
    - /users: User authentication and management.
    - /tests: Test and script management.

Usage:
Run with: uvicorn main:app --reload
"""
import os
from fastapi import FastAPI, File, UploadFile, Form, Request, Body
from fastapi.responses import JSONResponse
from werkzeug.utils import secure_filename
import shutil
from bson import ObjectId
from typing import Dict, Any, List, Optional
from pydantic import BaseModel
from users import router as users_router
from tests import add_script, add_scheme, router as tests_router
from models import ImageProcessingRequest
from database import db
from yolo_based_mark_detection import *


app = FastAPI(title="Marking API")

app.include_router(users_router, prefix="/users", tags=["users"])
app.include_router(tests_router, prefix="/tests", tags=["tests"])


class MarkSchemeRequest(BaseModel):
    file_id: str
    test_id: str
    end_number: int
    scheme_or_paper: bool
    mark_scheme: Optional[List[Dict[str, Any]]] = []


@app.get("/")
async def hello_world():
    return "Hello, Examiner!"


# @app.post("/mark")
# async def process_image(params: ImageProcessingRequest):
#     try:
#         # Download image from Cloudinary URL
#         image_path = f"temp_{os.path.basename(params.image_url)}"
#         download_image(params.image_url, image_path)

#         if not params.scheme_or_paper:
#             test = await db.tests.find_one({"_id": ObjectId(params.test_id)})
#             mark_scheme = test["scheme"]

#         # Process the image using MarkingScheme
#         scheme = MarkingScheme(
#             img_path=image_path,
#             test_id=params.test_id,
#             endNumber=params.end_number,
#             schemeOrPaper=params.scheme_or_paper,
#             mark_scheme=mark_scheme,
#         )
#         scheme.binarize_image()
#         scheme.retrieve_index_number()
#         scheme.markForMe()
#         results = scheme.modularize_scheme_or_ans()

#         # Clean up temporary file
#         os.remove(image_path)

#         print("Results:", results)

#         if params.scheme_or_paper:
#             # Add the results to the test
#             message = await add_scheme(params.test_id, results)
#         else:
#             # Add the results to the test
#             message = await add_script(params.test_id, results)

#         return {"message": message}

#     except Exception as e:
#         print("Error:", e)
#         return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/process_direct")
async def process_direct(
    file: UploadFile = File(...),
    test_id: str = Form(...),
    end_number: int = Form(...),
    scheme_or_paper: bool = Form(...),
):
    try:
        # Create a temporary file path to save the uploaded image
        temp_file_path = f"temp_{file.filename}"

        # Save the uploaded file
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # If we're marking an answer paper, we need the mark scheme
        if not scheme_or_paper:
            test = await db.tests.find_one({"_id": ObjectId(test_id)})
            mark_scheme = test["scheme"]
        else:
            mark_scheme = []

        # Process the image using MarkingScheme
        scheme = McqMarker(
            image_path=temp_file_path,
            test_id=test_id,
            total_questions=end_number,
            is_scheme=scheme_or_paper,
            scheme=mark_scheme,
        )
        scheme.start_shading_processing()

        # Process based on whether it's a scheme or answer paper
        if scheme_or_paper:
            pass
        else:
            scheme.start_indx_processing()

        scheme.start_answer_processing()
        results = scheme.marking_outcome()

        # Clean up temporary file
        os.remove(temp_file_path)

        # Save the results to the database
        if scheme_or_paper:
            message = await add_scheme(test_id, results)
        else:
            message = await add_script(test_id, results)

        return {"message": message}

    except Exception as e:
        print("Error:", e)
        # Clean up temp file if it exists
        if "temp_file_path" in locals() and os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        return JSONResponse(status_code=500, content={"error": str(e)})



# @app.post("/mark_scheme")
# async def mark_scheme(params: MarkSchemeRequest):
#     file_id = params.file_id
#     file_name = get_file_name(file_id)
#     download_file_from_telegram_storage_bucket(file_name)

#     params_test_id = params.test_id
#     params_end_number = params.end_number
#     params_scheme_or_paper = params.scheme_or_paper

#     try:
#         if not params_scheme_or_paper:
#             params_mark_scheme = params.mark_scheme
#             scheme = MarkingScheme(
#                 img_path=file_name,
#                 test_id=params_test_id,
#                 endNumber=params_end_number,
#                 schemeOrPaper=False,
#                 mark_scheme=params_mark_scheme,
#             )
#             scheme.binarize_image()
#             scheme.retrieve_index_number()
#             scheme.markForMe()
#             results = scheme.modularize_scheme_or_ans()
#             os.remove(file_name)
#             return {"data": results}
#         else:
#             scheme = MarkingScheme(
#                 img_path=file_name,
#                 test_id=params_test_id,
#                 endNumber=params_end_number,
#                 schemeOrPaper=True,
#                 mark_scheme=[],
#             )
#             scheme.binarize_image()
#             scheme.retrieve_aca_year()
#             scheme.markForMe()
#             results = scheme.modularize_scheme_or_ans()
#             os.remove(file_name)
#             return {"data": results}
#     except Exception as e:
#         return JSONResponse(status_code=500, content={"error": str(e)})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
    # uvicorn main:app --host 0.0.0.0 --port 8000 --reload
