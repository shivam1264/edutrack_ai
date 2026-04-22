@echo off
echo Committing and pushing changes to GitHub...
git add .
git commit -m "Update EduTrack AI project - %date% %time%"
git push
echo Done!
pause
