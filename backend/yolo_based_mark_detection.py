"""
yolo_based_mark_detection.py

YOLO-based mark detection and grading logic for MCQ Grader backend.

Features:
- Downloads YOLO model weights from AWS S3 for local inference.
- Loads and resizes answer sheet images for processing.
- Detects regions of interest (ROI) for index numbers and answers using YOLO.
- Calculates bubble centers for index and answer regions.
- Maps detected marks to bubbles for extracting index numbers and answers.
- Generates mark schemes from correctly shaded sheets.
- Grades student answer sheets against a mark scheme.
- Visualizes detected ROIs and marks for debugging and verification.

Classes:
- McqMarker: Main class for image processing, mark detection, and grading.

Usage:
Instantiate McqMarker with image path, test ID, total questions, and scheme flag.
Call methods to process shading, extract index, extract answers, and calculate score.
"""
import os
import boto3
from botocore.exceptions import ClientError
import cv2
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure
from ultralytics import YOLO 


class McqMarker:
    def __init__(self, image_path, test_id, total_questions, is_scheme, scheme=[]) -> None:
        self.image_path = image_path

        # --- Target Image Dimensions for Processing ---
        # This is the fixed size your input image will be resized to.
        self.width = 2100
        self.height = 3050

        # --- Initializing ROI coordinates. They will be populated by the model's detections. ---
        self.indx_roi_coords = None
        self.answers_roi_coords = None

        # --- S3 Model Configuration ---
        self.s3_bucket_name = os.getenv("S3_BUCKET_NAME", "mcq-marker-models")
        self.s3_model_key = os.getenv("S3_MODEL_KEY", "best_omr_model.pt")
        self.local_model_path = os.getenv("LOCAL_MODEL_PATH", "/tmp/best_omr_model.pt")
   
        # Download model from S3
        self._download_model_from_s3()

        self.model_path = self.local_model_path
        self.detected_indx_marks = []
        self.detected_answers_marks = []
        self.test_id = test_id
        self.questions = total_questions
        self.is_scheme = is_scheme
        self.index_number = ""
        self.student_answer = []
        self.mark_scheme = scheme
        self.score = 0
        self.options = ['A', 'B', 'C', 'D', 'E']

    def _download_model_from_s3(self):
        # Check if the model already exists locally to avoid re-downloading
        if os.path.exists(self.local_model_path):
            print(f"Model already exists at {self.local_model_path}, skipping download.")
            return

        s3 = boto3.client('s3')
        try:
            print(f"Downloading model {self.s3_model_key} from S3 bucket {self.s3_bucket_name} to {self.local_model_path}...")
            s3.download_file(self.s3_bucket_name, self.s3_model_key, self.local_model_path)
            print("Model downloaded successfully.")
        except ClientError as e:
            if e.response['Error']['Code'] == "404":
                print(f"The object {self.s3_model_key} was not found in bucket {self.s3_bucket_name}.")
            else:
                raise
        except Exception as e:
            print(f"An unexpected error occurred during S3 download: {e}")
            raise

    def load_image(self):
        image = cv2.imread(self.image_path)
        if image is None:
            print("Error: Could not load image.")
            exit()

        img = cv2.resize(image, (self.width, self.height))
        return img

    def start_indx_processing(self):
        if self.indx_roi_coords is None:
            print("Error: Index ROI coordinates not detected by the model.")
            return

        # Use fixed reduction from detected ROI
        orig_x_start, orig_y_start, orig_x_end, orig_y_end = self.indx_roi_coords
        padding_x = (orig_x_end - orig_x_start) * 0.05
        padding_y_t = (orig_y_end - orig_y_start) * 0.095
        padding_y_b = (orig_y_end - orig_y_start) * 0.08
        x_start = orig_x_start + padding_x
        y_start = orig_y_start + padding_y_t
        x_end = orig_x_end - padding_x
        y_end = orig_y_end - padding_y_b
        
        roi_height = y_end - y_start
        roi_width = x_end - x_start
        num_columns = 7
        num_digits_per_column = 10

        if roi_height <= 0 or roi_width <= 0:
            print("Error: Detected Index ROI dimensions are invalid.")
            return

        column_width_segment = roi_width / num_columns
        digit_row_height_segment = roi_height / num_digits_per_column
        
        # --- Create a list of all digit bubble centers ---
        digit_centers = []
        for col_idx in range(num_columns):
            for digit in range(num_digits_per_column):
                center_x = x_start + (col_idx * column_width_segment) + (column_width_segment / 2)
                center_y = y_start + (digit * digit_row_height_segment) + (digit_row_height_segment / 2)
                digit_centers.append({
                    'x': center_x,
                    'y': center_y,
                    'col': col_idx,
                    'digit': str(digit)
                })

        # --- Map detected marks to the closest digit center ---
        marks_per_column = [[] for _ in range(num_columns)]
        for mark in self.detected_indx_marks:
            min_dist = float('inf')
            closest_digit_center = None
            for center in digit_centers:
                dist = np.sqrt((mark['center_x'] - center['x'])**2 + (mark['center_y'] - center['y'])**2)
                if dist < min_dist:
                    min_dist = dist
                    closest_digit_center = center
            
            if closest_digit_center:
                marks_per_column[closest_digit_center['col']].append(closest_digit_center['digit'])
        
        index_digits = ['X'] * num_columns
        for col_idx in range(num_columns):
            marks_in_col = marks_per_column[col_idx]
            print(f"\ncol-idx: {col_idx}, marks: {marks_in_col}")
            if not marks_in_col:
                index_digits[col_idx] = 'X'
            else:
                unique_digits = list(set(marks_in_col))
                if len(unique_digits) == 1:
                    index_digits[col_idx] = unique_digits[0]
                else:
                    index_digits[col_idx] = 'M' 

        indxNo = "".join(index_digits)
        print(f"\nindexNo: {indxNo}")
        self.index_number = indxNo

        indx_roi_img = self.load_image()
        print(f"\nShape: {indx_roi_img.shape}")

        for mark in self.detected_indx_marks:
            cv2.circle(indx_roi_img, (int(mark['center_x']), int(mark['center_y'])), 5, (0, 255, 0), -1)
            cv2.putText(indx_roi_img, f"{mark['confidence']:.2f}", (int(mark['center_x']) + 10, int(mark['center_y']) - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 255, 0), 1)

        # Draw the original detected ROI (Red)
        cv2.rectangle(indx_roi_img, (int(orig_x_start), int(orig_y_start)), 
                      (int(orig_x_end), int(orig_y_end)), (0, 0, 255), 2)
        # Draw the new, reduced calculation ROI (Yellow)
        cv2.rectangle(indx_roi_img, (int(x_start), int(y_start)), 
                      (int(x_end), int(y_end)), (0, 255, 255), 2)

        # Draw column and row lines for verification
        for i in range(1, num_columns):
            x_line = int(x_start + i * column_width_segment)
            cv2.line(indx_roi_img, (x_line, int(y_start)), (x_line, int(y_end)), (255, 0, 0), 1)
        for i in range(1, num_digits_per_column):
            y_line = int(y_start + i * digit_row_height_segment)
            cv2.line(indx_roi_img, (int(x_start), y_line), (int(x_end), y_line), (255, 0, 0), 1)

        figure(figsize=(20,20), dpi=90)
        plt.imshow(cv2.cvtColor(indx_roi_img, cv2.COLOR_BGR2RGB))
        plt.title("Detected Index ROI (Red) and Calculation Bounding Box (Yellow)")
        plt.axis('off')
        plt.savefig('index_roi_plot.png')
        print("Plot saved to index_roi_plot.png")
        plt.close()

    def _calculate_bubble_centers(self, x_start, y_start, roi_width, roi_height):
        bubble_centers = {}
        
        # --- Ratios for column boundaries based on your reference ---
        column_definitions_ratios = {
            "firstCol":  (35 / 965,  175 / 965),
            "secondCol": (235 / 965, 375 / 965),
            "thirdCol":  (435 / 965, 570 / 965),
            "fourthCol": (635 / 965, 770 / 965),
            "fifthCol":  (830 / 965, 965 / 965)
        }

        # --- Ratios for vertical grid (rows and gaps) ---
        questions_per_column = 40
        options_per_question = len(self.options)
        questions_per_group = 5
        num_groups_per_column = 8
        num_gaps = num_groups_per_column - 1

        total_question_height_ratio = 1 - (num_gaps * 0.022) 
        segment_height_ratio = total_question_height_ratio / questions_per_column
        gap_height_ratio = 0.022

        current_y_ratio = 0
        q_num = 1
        
        column_boundaries = {}
        for col_name, (start_ratio, end_ratio) in column_definitions_ratios.items():
            start_px = int(roi_width * start_ratio)
            end_px = int(roi_width * end_ratio)
            column_boundaries[col_name] = (start_px, end_px)

        for col_name, (col_start_px, col_end_px) in column_boundaries.items():
            col_width_px = col_end_px - col_start_px
            option_width_px = col_width_px / options_per_question
            
            current_y_ratio = 0
            for group_idx in range(num_groups_per_column):
                for q_in_group_idx in range(questions_per_group):
                    q_center_y_ratio = current_y_ratio + (segment_height_ratio / 2)
                    q_center_y_px = int(q_center_y_ratio * roi_height)
                    
                    for option_idx in range(options_per_question):
                        x_center_px = col_start_px + (option_idx * option_width_px) + (option_width_px / 2)
                        
                        bubble_center = {
                            'x': x_center_px + x_start,
                            'y': q_center_y_px + y_start,
                            'option': self.options[option_idx]
                        }
                        
                        if q_num not in bubble_centers:
                            bubble_centers[q_num] = []
                        bubble_centers[q_num].append(bubble_center)
                        
                    current_y_ratio += segment_height_ratio
                    q_num += 1
                
                if group_idx < num_gaps:
                    current_y_ratio += gap_height_ratio
        
        return bubble_centers, column_boundaries, segment_height_ratio, gap_height_ratio


    def start_answer_processing(self):
        if self.answers_roi_coords is None:
            print("Error: Answers ROI coordinates not detected by the model.")
            return

        # Use fixed reduction from detected ROI
        orig_x_start, orig_y_start, orig_x_end, orig_y_end = self.answers_roi_coords
        padding_x_l = (orig_x_end - orig_x_start) * 0.05
        padding_x_r = (orig_x_end - orig_x_start) * 0.04
        padding_y_t = (orig_y_end - orig_y_start) * 0.04
        padding_y_b = (orig_y_end - orig_y_start) * 0.04
        x_start = orig_x_start + padding_x_l
        y_start = orig_y_start + padding_y_t
        x_end = orig_x_end - padding_x_r
        y_end = orig_y_end - padding_y_b

        roi_height = y_end - y_start
        roi_width = x_end - x_start
        
        # Calculate bubble centers based on the new, robust, ratio-based grid
        bubble_centers_by_q, column_boundaries, segment_height_ratio, gap_height_ratio = self._calculate_bubble_centers(
            x_start, y_start, roi_width, roi_height
        )
        
        # --- Map detected marks to the closest bubble center ---
        marks_per_question = {}
        for mark in self.detected_answers_marks:
            min_dist = float('inf')
            closest_bubble_center = None
            closest_q_num = None
            
            for q_num, centers in bubble_centers_by_q.items():
                for center in centers:
                    dist = np.sqrt((mark['center_x'] - center['x'])**2 + (mark['center_y'] - center['y'])**2)
                    if dist < min_dist:
                        min_dist = dist
                        closest_bubble_center = center
                        closest_q_num = q_num
            
            if closest_q_num is not None:
                if closest_q_num not in marks_per_question:
                    marks_per_question[closest_q_num] = []
                marks_per_question[closest_q_num].append(closest_bubble_center['option'])

        for q_num in range(1, self.questions + 1):
            if q_num in marks_per_question:
                detected_options = marks_per_question[q_num]
                unique_options = list(set(detected_options))
                
                if len(unique_options) == 1:
                    detected_answer = unique_options[0]
                else:
                    detected_answer = 'M' # Multiple different marks
            else:
                detected_answer = 'X'


            if self.is_scheme:
                self.mark_scheme.append({
                    'answer_to': q_num,
                    'answer': detected_answer
                })
            else:
                if len(self.mark_scheme) >= q_num:
                    correct_answer = self.mark_scheme[q_num - 1]['answer']
                else:
                    correct_answer = '?'
                
                self.student_answer.append({
                    'answer_to': q_num,
                    'answer': detected_answer,
                    'correct_answer': correct_answer
                })

        answer_roi_img = self.load_image()

        for mark in self.detected_answers_marks:
            cv2.circle(answer_roi_img, (int(mark['center_x']), int(mark['center_y'])), 5, (0, 255, 0), -1)
            cv2.putText(answer_roi_img, f"{mark['confidence']:.2f}", (int(mark['center_x']) + 10, int(mark['center_y']) - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 255, 0), 1)

        # Draw the original detected ROI (Red)
        cv2.rectangle(answer_roi_img, (int(orig_x_start), int(orig_y_start)), 
                      (int(orig_x_end), int(orig_y_end)), (0, 0, 255), 2)
        # Draw the new, reduced calculation ROI (Yellow)
        cv2.rectangle(answer_roi_img, (int(x_start), int(y_start)), 
                      (int(x_end), int(y_end)), (0, 255, 255), 2)
        
        # --- Draw the new ratio-based grid for verification ---
        for col_name, (col_start_px, col_end_px) in column_boundaries.items():
            cv2.line(answer_roi_img, (int(x_start + col_start_px), int(y_start)), 
                     (int(x_start + col_start_px), int(y_end)), (255, 0, 0), 1)
            cv2.line(answer_roi_img, (int(x_start + col_end_px), int(y_start)), 
                     (int(x_start + col_end_px), int(y_end)), (255, 0, 0), 1)
        
        current_y_ratio = 0
        questions_per_group = 5
        num_groups_per_column = 8
        num_gaps = num_groups_per_column - 1
        
        total_question_height_ratio = 1 - (num_gaps * 0.022)
        segment_height_ratio = total_question_height_ratio / (questions_per_group * num_groups_per_column)
        gap_height_ratio = 0.022

        current_y_ratio = 0
        for group_idx in range(num_groups_per_column):
            for q_in_group_idx in range(questions_per_group):
                y_line = int(y_start + (current_y_ratio + segment_height_ratio) * roi_height)
                cv2.line(answer_roi_img, (int(x_start), y_line), (int(x_end), y_line), (255, 0, 0), 1)
                current_y_ratio += segment_height_ratio
            
            if group_idx < num_gaps:
                y_line = int(y_start + (current_y_ratio + gap_height_ratio) * roi_height)
                cv2.line(answer_roi_img, (int(x_start), y_line), (int(x_end), y_line), (255, 255, 0), 2)
                current_y_ratio += gap_height_ratio
        

        figure(figsize=(20,20), dpi=90)
        plt.imshow(cv2.cvtColor(answer_roi_img, cv2.COLOR_BGR2RGB))
        plt.title("Detected Answers ROI (Red) and Calculation Bounding Box (Yellow)")
        plt.axis('off')
        plt.savefig('answers_roi_plot.png')
        print("Plot saved to answers_roi_plot.png")
        plt.close()   

    def calculate_score(self):
        """
        Calculates the score of the student's paper by comparing detected answers
        with the provided mark scheme.
        """
        if self.is_scheme:
            print("Cannot calculate score for a mark scheme.")
            return

        self.score = 0
        for student_ans in self.student_answer:
            if student_ans['answer'] == student_ans['correct_answer'] and student_ans['answer'] not in ['X', 'M']:
                self.score += 1
        
        print(f"\nStudent Score: {self.score}/{self.questions}")       

    def start_shading_processing(self):
        model = YOLO(self.model_path)
        img = self.load_image()

        results = model(img, conf=0.25, iou=0.7)

        for r in results:
            for box in r.boxes:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                class_id = int(box.cls[0])
                confidence = float(box.conf[0])
                
                if class_id == 1:
                    self.indx_roi_coords = (x1, y1, x2, y2)
                elif class_id == 2:
                    self.answers_roi_coords = (x1, y1, x2, y2)
                elif class_id == 0:
                    center_x = (x1 + x2) / 2
                    center_y = (y1 + y2) / 2
                    
                    self.detected_indx_marks.append({
                        "center_x": center_x,
                        "center_y": center_y,
                        "confidence": confidence,
                    })
                    self.detected_answers_marks.append({
                        "center_x": center_x,
                        "center_y": center_y,
                        "confidence": confidence,
                    })
                    
        if self.indx_roi_coords:
            x_start, y_start, x_end, y_end = self.indx_roi_coords
            self.detected_indx_marks = [
                mark for mark in self.detected_indx_marks
                if x_start <= mark['center_x'] < x_end and y_start <= mark['center_y'] < y_end
            ]

        if self.answers_roi_coords:
            x_start, y_start, x_end, y_end = self.answers_roi_coords
            self.detected_answers_marks = [
                mark for mark in self.detected_answers_marks
                if x_start <= mark['center_x'] < x_end and y_start <= mark['center_y'] < y_end
            ]


    def marking_outcome(self):
        if self.is_scheme:
            return {
                'scheme' : self.mark_scheme
            }
        else:
            self.calculate_score()
            return {
                'answers': self.student_answer,
                'index_number': self.index_number,
                'score': self.score,
                'out_of': self.questions
            }


if __name__ == '__main__':
    # --- Example Usage ---

    # --- Step 1: Create a mark scheme from a correctly shaded sheet ---
    print("--- Processing Mark Scheme ---")
    mark_scheme_path = '/home/mysom/Downloads/Cloudinary_Archive_2025-07-30_17_09_40_Originals/1753889363371292.jpg'
    scheme_marker = McqMarker(
        image_path=mark_scheme_path, 
        test_id='test001', 
        total_questions=130, 
        is_scheme=True
    )
    scheme_marker.start_shading_processing()
    scheme_marker.start_indx_processing()
    scheme_marker.start_answer_processing()

    generated_scheme = scheme_marker.mark_scheme
    print(f"\nGenerated Mark Scheme: {generated_scheme}")

    # --- Step 2: Grade a student's paper using the generated scheme ---
    print("\n--- Processing Student Paper ---")
    student_paper_path = '/home/mysom/Downloads/Cloudinary_Archive_2025-07-30_17_09_40_Originals/1753889363371292.jpg'
    student_marker = McqMarker(
        image_path=student_paper_path, 
        test_id='test001', 
        total_questions=130, 
        is_scheme=False,
        scheme=generated_scheme
    )
    student_marker.start_shading_processing()
    student_marker.start_indx_processing()
    student_marker.start_answer_processing()
    student_marker.calculate_score()