//
//  NotesTableViewController.swift
//  Go Map!!
//
//  Created by Bryce Cogswell on 11/4/14.
//  Copyright (c) 2014 Bryce Cogswell. All rights reserved.
//

import MapKit
import UIKit

class NotesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
	var newComment: String?

	@IBOutlet var tableView: UITableView!
	var note: OsmNoteMarker!
	var mapView: MapView!

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.estimatedRowHeight = 100
		tableView.rowHeight = UITableView.automaticDimension

		// add extra space at bottom so keyboard doesn't cover elements
		var rc = tableView.contentInset
		rc.bottom += 70
		tableView.contentInset = rc
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	// MARK: - Table view data source

	func numberOfSections(in tableView: UITableView) -> Int {
		return note.comments.count > 0 ? 2 : 1
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if note.comments.count > 0, section == 0 {
			return NSLocalizedString("Note History", comment: "OSM note")
		} else {
			return NSLocalizedString("Update", comment: "update an osm note")
		}
	}

	func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 1 {
			return "\n\n\n\n\n\n\n\n\n"
		}
		return nil
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 && note.comments.count > 0 ? note.comments.count : 2
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0, note.comments.count > 0 {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "noteCommentCell",
				for: indexPath) as! NotesCommentCell
			let comment = note.comments[indexPath.row]
			let user = comment.user.count > 0 ? comment.user : "anonymous"
			cell.date.text = comment.date
			cell.user.text = user
			cell.action.text = comment.action
			if comment.text.count == 0 {
				cell.commentBackground.isHidden = true
				cell.comment.text = nil
			} else {
				cell.commentBackground.isHidden = false
				cell.commentBackground.layer.cornerRadius = 5
				cell.commentBackground.layer.borderColor = UIColor.black.cgColor
				cell.commentBackground.layer.borderWidth = 1.0
				cell.commentBackground.layer.masksToBounds = true
				cell.comment.text = comment.text
			}
			return cell
		} else if indexPath.row == 0 {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "noteResolveCell",
				for: indexPath) as! NotesResolveCell
			cell.textView.layer.cornerRadius = 5.0
			cell.textView.layer.borderColor = UIColor.black.cgColor
			cell.textView.layer.borderWidth = 1.0
			cell.textView.delegate = self
			cell.textView.text = newComment
			cell.commentButton.isEnabled = false
			cell.resolveButton.isEnabled = note?.comments != nil
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "noteDirectionsCell",
				for: indexPath) as UITableViewCell
			return cell
		}
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		view.endEditing(true)

		if note?.comments != nil, indexPath.section == 0 {
			// ignore
		} else if indexPath.row == 1 {
			// get directions
			let coordinate = CLLocationCoordinate2DMake(self.note.lat, self.note.lon)
			let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
			let note = MKMapItem(placemark: placemark)
			note.name = "OSM Note"
			let current = MKMapItem.forCurrentLocation()
			let options = [
				MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
			]
			MKMapItem.openMaps(with: [current, note], launchOptions: options)
		}
	}

	func commentAndResolve(_ resolve: Bool, sender: UIView?) {
		view.endEditing(true)
		guard let cell: NotesResolveCell = sender?.superviewOfType()
		else { return }

		let s = cell.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let alert = UIAlertController(
			title: NSLocalizedString("Updating Note...", comment: "OSM Note"),
			message: nil,
			preferredStyle: .alert)
		present(alert, animated: true)

		mapView.notesDatabase.update(note: note, close: resolve, comment: s) { [self] result in
			alert.dismiss(animated: true)
			switch result {
			case let .success(newNote):
				note = newNote
				DispatchQueue.main.async(execute: { [self] in
					done(nil)
					mapView.refreshNoteButtonsFromDatabase()
				})
			case let .failure(error):
				let alert2 = UIAlertController(
					title: NSLocalizedString("Error", comment: ""),
					message: error.localizedDescription,
					preferredStyle: .alert)
				alert2
					.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
				present(alert2, animated: true)
			}
		}
	}

	@IBAction func doComment(_ sender: Any) {
		commentAndResolve(false, sender: sender as? UIView)
	}

	@IBAction func doResolve(_ sender: Any) {
		commentAndResolve(true, sender: sender as? UIView)
	}

	func textViewDidChange(_ textView: UITextView) {
		if let cell: NotesResolveCell = textView.superviewOfType() {
			newComment = cell.textView.text
			let s = newComment?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
			cell.commentButton.isEnabled = (s?.count ?? 0) > 0
		}
	}

	@IBAction func done(_ sender: Any?) {
		dismiss(animated: true)
	}
}

class NotesCommentCell: UITableViewCell {
	@IBOutlet var date: UILabel!
	@IBOutlet var user: UILabel!
	@IBOutlet var action: UILabel!
	@IBOutlet var comment: UITextView!
	@IBOutlet var commentBackground: UIView!
}

class NotesResolveCell: UITableViewCell {
	@IBOutlet var textView: UITextView!
	@IBOutlet var commentButton: UIButton!
	@IBOutlet var resolveButton: UIButton!
}
